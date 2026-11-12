import {
  BadRequestException,
  ConflictException,
  Injectable,
} from '@nestjs/common';
import { OrderItemsRepository } from '../../orders/order-items/order-items.repository';
import { OrderItemsService } from '../../orders/order-items/order-items.service';
import { OrdersRepository } from '../../orders/orders/orders.repository';
import { OrdersService } from '../../orders/orders/orders.service';
import { CancelOrderDTO } from '../../orders/orders/dto/order.dto';
import { assertExists } from '../../../shared/assertions/assert-exists';
import { UsersRepository } from '../../users/users.repository';
import { UsersService } from '../../users/users.service';
import { HandoffRepository } from '../handoff/handoff.repository';
import { HandoffService } from '../handoff/handoff.service';
import { KitchenQcRepository } from '../kitchen-qc/kitchen-qc.repository';
import { KitchenQcService } from '../kitchen-qc/kitchen-qc.service';
import { KitchenTicketRepository } from '../kitchen-ticket/kitchen-ticket.repository';
import { KitchenTicketService } from '../kitchen-ticket/kitchen-ticket.service';
import { OrderItemQcRejectionRepository } from '../order-item-qc-rejection/order-item-qc-rejection.repository';
import { OrderItemQcRejectionService } from '../order-item-qc-rejection/order-item-qc-rejection.service';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import { CreateHandoffDTO } from '../handoff/dto/create-handoff.dto';
import { OrderChannel, OrderItemQcRejection } from '@prisma/client';
import { RejectQcAttemptDTO } from './dto/reject-qc-attempt.dto';

@Injectable()
export class KitchenFulfillmentService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly kitchenTicketService: KitchenTicketService,
    private readonly kitchenTicketRepository: KitchenTicketRepository,
    private readonly kitchenQcService: KitchenQcService,
    private readonly kitchenQcRepository: KitchenQcRepository,
    private readonly orderItemQcRejectionService: OrderItemQcRejectionService,
    private readonly orderItemQcRejectionRepository: OrderItemQcRejectionRepository,
    private readonly handoffService: HandoffService,
    private readonly handoffRepository: HandoffRepository,
    private readonly usersService: UsersService,
    private readonly usersRepository: UsersRepository,
    private readonly ordersService: OrdersService,
    private readonly ordersRepository: OrdersRepository,
    private readonly orderItemsService: OrderItemsService,
    private readonly orderItemsRepository: OrderItemsRepository,
  ) {}

  async acknowledge(kitchenTicketId: string) {
    const ticket = await this.kitchenTicketService.acknowledge(kitchenTicketId);
    this.kitchenTicketService.notifyChange();
    return ticket;
  }

  async prepare(kitchenTicketId: string, callerId: string) {
    const result = await this.prisma.$transaction(async (tx) => {
      const ticket = await this.kitchenTicketService.prepare(
        kitchenTicketId,
        callerId,
        tx,
      );

      const order = await this.ordersService.prepare(ticket.order_id, tx);

      return { ticket, order };
    });

    this.kitchenTicketService.notifyChange();
    return result;
  }

  async forChecking(kitchenTicketId: string, callerId: string) {
    const ticket = await this.kitchenTicketService.forChecking(
      kitchenTicketId,
      callerId,
    );
    this.kitchenTicketService.notifyChange();
    return ticket;
  }

  async check(kitchenTicketId: string, callerId: string) {
    const result = await this.prisma.$transaction(async (tx) => {
      const attempt = await this.kitchenQcService.create(
        callerId,
        kitchenTicketId,
        tx,
      );

      const ticket = await this.kitchenTicketService.check(
        kitchenTicketId,
        callerId,
        tx,
      );

      return { ticket, attempt };
    });

    this.kitchenTicketService.notifyChange();
    return result;
  }

  async passQCAttempt(attemptId: string, callerId: string) {
    const result = await this.prisma.$transaction(async (tx) => {
      const attempt = await this.kitchenQcService.passAttempt(
        callerId,
        attemptId,
        tx,
      );

      const ticket = await this.kitchenTicketService.ready(
        attempt.kitchen_ticket_id,
        callerId,
        tx,
      );

      return { ticket, attempt };
    });

    this.kitchenTicketService.notifyChange();
    return result;
  }

  async rejectQcAttempt(
    attemptId: string,
    callerId: string,
    dto: RejectQcAttemptDTO,
  ) {
    const result = await this.prisma.$transaction(async (tx) => {
      const rejections: OrderItemQcRejection[] = [];

      for (const rejection of dto.rejections) {
        const { order_item_id, ...rejectionDto } = rejection;

        rejections.push(
          await this.orderItemQcRejectionService.create(
            attemptId,
            order_item_id,
            rejectionDto,
            tx,
          ),
        );
      }

      const attempt = await this.kitchenQcService.failAttempt(
        attemptId,
        callerId,
        tx,
      );

      const ticket = await this.kitchenTicketService.rework(
        attempt.kitchen_ticket_id,
        callerId,
        tx,
      );

      return { ticket, attempt, rejections };
    });

    this.kitchenTicketService.notifyChange();
    return result;
  }

  async handOver(
    kitchenTicketId: string,
    actorId: string,
    dto?: CreateHandoffDTO,
  ) {
    const result = await this.prisma.$transaction(async (tx) => {
      const ticket = await this.kitchenTicketService.findOne(
        kitchenTicketId,
        tx,
      );

      const order = await this.ordersService.complete(ticket.order_id, tx);

      if (this.isDelivery(order.order_channel)) {
        if (!dto) {
          throw new BadRequestException({
            code: 'EMPTY_HANDOFF_IMAGES',
            message: 'Delivery order handoffs must have images.',
          });
        }

        await this.handoffService.create(kitchenTicketId, actorId, dto, tx);
      }

      const handedOverTicket = await this.kitchenTicketService.handOver(
        kitchenTicketId,
        tx,
      );

      return {
        order: { ...order, kitchen_tickets_order: handedOverTicket },
        handedOverTicket,
      };
    });

    this.kitchenTicketService.notifyChange();
    return result;
  }

  async cancel(
    brandId: string,
    orderId: string,
    actorId: string,
    dto: CancelOrderDTO,
  ) {
    const result = await this.ordersRepository.transaction(async (tx) => {
      const existing = await this.ordersRepository.findByBrand(
        brandId,
        orderId,
        tx,
      );
      assertExists(existing, 'Order', orderId);

      if (!existing.kitchen_tickets_order) {
        throw new ConflictException({
          code: 'ORDER_HAS_NO_KITCHEN_TICKET',
          message: 'Cancel draft orders through the orders endpoint.',
        });
      }

      const ticket = await this.kitchenTicketService.cancel(
        existing.kitchen_tickets_order.kitchen_ticket_id,
        tx,
      );
      const order = await this.ordersService.cancel(
        brandId,
        orderId,
        actorId,
        dto,
        tx,
      );

      return { order, ticket };
    });

    this.kitchenTicketService.notifyChange();
    return result;
  }

  private isDelivery(channel: OrderChannel) {
    return (
      channel === OrderChannel.GRABFOOD || channel === OrderChannel.FOODPANDA
    );
  }
}
