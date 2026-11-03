import {
  ConflictException,
  Injectable,
  ServiceUnavailableException,
} from '@nestjs/common';
import {
  OrderChannel,
  OrderStatus,
  PaymentMethod,
  PaymentStatus,
  Prisma,
} from '@prisma/client';
import { setTimeout as delay } from 'node:timers/promises';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import type { OrderItemsService } from '../order-items/order-items.service';
import type { CreateOrderDTO } from './dto/order.dto';

const includeOrder = {
  order_items_order: { include: { order_item_modifiers_order_item: true } },
  kitchen_tickets_order: true,
} satisfies Prisma.OrderInclude;
export type SavedOrder = Prisma.OrderGetPayload<{
  include: typeof includeOrder;
}>;

type CreateOrderContext = {
  brandId: string;
  actorId: string;
  orderCode: string;
  hash: string;
  number: number;
  order_date: Date;
  created_at: Date;
  lines: Awaited<ReturnType<OrderItemsService['snapshots']>>;
  payment?: { payment_method: PaymentMethod; payment_status: PaymentStatus };
};

@Injectable()
export class OrdersRepository {
  constructor(private readonly prisma: PrismaService) {}

  create(
    dto: CreateOrderDTO,
    context: CreateOrderContext,
    tx: Prisma.TransactionClient,
  ) {
    return tx.order.create({
      data: {
        order_id: dto.order_id,
        order_channel: dto.order_channel,
        merchant_store_reference: dto.merchant_store_reference,
        external_order_reference: dto.external_order_reference,
        table_reference: dto.table_reference,
        notes: dto.notes,
        brand_id: context.brandId,
        created_by_id: context.actorId,
        order_code: context.orderCode,
        order_number: context.number,
        order_date: context.order_date,
        created_at: context.created_at,
        create_request_hash: context.hash,
        ...context.payment,
        order_items_order: {
          create: context.lines.map((line) => ({
            menu_item_id: line.menu_item_id,
            item_name: line.item_name,
            quantity: line.quantity,
            unit_price: line.unit_price,
            notes: line.notes,
            order_item_modifiers_order_item: { create: line.modifiers },
          })),
        },
      },
      include: includeOrder,
    });
  }

  createTicket(
    orderId: string,
    orderCode: string,
    ticketNumber: string,
    actorId: string,
    tx: Prisma.TransactionClient,
  ) {
    return tx.kitchenTicket.create({
      data: {
        order_id: orderId,
        order_code: orderCode,
        ticket_number: ticketNumber,
        created_by_id: actorId,
      },
    });
  }

  findById(
    orderId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.order.findUnique({
      where: { order_id: orderId },
      include: includeOrder,
    });
  }

  findPlatformOrder(
    channel: OrderChannel,
    merchant: string,
    external: string,
    tx: Prisma.TransactionClient,
  ) {
    return tx.order.findFirst({
      where: {
        order_channel: channel,
        merchant_store_reference: merchant,
        external_order_reference: external,
      },
      include: includeOrder,
    });
  }

  findActiveBrand(brandId: string, tx: Prisma.TransactionClient) {
    return tx.brand.findFirst({
      where: { brand_id: brandId, is_active: true },
    });
  }

  findByBrand(
    brandId: string,
    orderId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.order.findFirst({
      where: { order_id: orderId, brand_id: brandId },
      include: includeOrder,
    });
  }

  update(
    orderId: string,
    data: Prisma.OrderUncheckedUpdateInput,
    tx: Prisma.TransactionClient,
  ) {
    return tx.order.update({
      where: { order_id: orderId },
      data,
      include: includeOrder,
    });
  }

  async updateStatus(
    orderId: string,
    newStatus: OrderStatus,
    expectedStatus: OrderStatus,
    extraData: Prisma.OrderUpdateInput,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.order.update({
      where: {
        order_id: orderId,
        status: expectedStatus,
      },
      data: {
        ...extraData,
        status: newStatus,
        modified_at: new Date(),
      },
      include: includeOrder,
    });
  }

  // Serialization retries rerun the entire transaction, never a partial confirmation.
  async transaction<T>(
    work: (tx: Prisma.TransactionClient) => Promise<T>,
  ): Promise<T> {
    for (let attempt = 0; attempt < 5; attempt++) {
      try {
        return await this.prisma.$transaction(work, {
          isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
        });
      } catch (error) {
        if (!isRetryableConflict(error)) throw error;
        if (attempt === 4)
          throw new ConflictException({
            statusCode: 409,
            error: 'Conflict',
            code: 'ORDER_RETRY_REQUIRED',
            message: 'Concurrent order request; retry using the same order ID.',
          });
        // Avoid immediate retry storms when multiple terminals confirm at once.
        await delay(10 * 2 ** attempt + Math.floor(Math.random() * 10));
      }
    }
    throw new ServiceUnavailableException();
  }

  async nextOrderNumber(brandId: string, tx: Prisma.TransactionClient) {
    // Keep creation time and the Manila date aligned regardless of database timezone.
    const [{ created_at, order_date }] = await tx.$queryRaw<
      { created_at: Date; order_date: Date }[]
    >`SELECT CURRENT_TIMESTAMP AS created_at, (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila')::date AS order_date`;
    const counter = await tx.orderDailyCounter.upsert({
      where: { brand_id_order_date: { brand_id: brandId, order_date } },
      create: { brand_id: brandId, order_date, last_number: 1 },
      update: { last_number: { increment: 1 } },
    });
    return { created_at, order_date, number: counter.last_number };
  }

  async nextTicketNumber(tx: Prisma.TransactionClient) {
    const [sequence] = await tx.$queryRaw<
      { number: bigint }[]
    >`SELECT nextval('kitchen_ticket_number_seq') AS number`.catch(
      (error: unknown) => {
        if (
          error instanceof Prisma.PrismaClientKnownRequestError &&
          error.code === 'P2010' &&
          error.meta?.code === '2200H'
        )
          throw new ConflictException('Ticket number capacity exhausted.');
        throw error;
      },
    );
    return sequence;
  }
}

function isRetryableConflict(error: unknown): boolean {
  if (error instanceof Prisma.PrismaClientKnownRequestError)
    return ['P2034', 'P2002'].includes(error.code);

  // The pg adapter can surface a COMMIT failure before Prisma wraps it as
  // P2034. Retry only explicit serialization/deadlock errors, never ambiguous
  // connection failures whose commit outcome is unknown.
  if (
    !(error instanceof Error) ||
    error.name !== 'DriverAdapterError' ||
    !('cause' in error)
  )
    return false;
  const cause: unknown = error.cause;
  return (
    typeof cause === 'object' &&
    cause !== null &&
    'kind' in cause &&
    cause.kind === 'TransactionWriteConflict' &&
    'originalCode' in cause &&
    (cause.originalCode === '40001' || cause.originalCode === '40P01')
  );
}
