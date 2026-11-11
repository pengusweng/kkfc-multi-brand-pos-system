import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import { CreateKitchenTicketDTO } from './dto/create-kitchen-ticket.dto';
import { KitchenTicketStatus, Prisma } from '@prisma/client';

// Kitchen views need item identities (for QC rejections) but never prices or
// restricted recipe snapshots.
const includeOrderItems = {
  order: {
    select: {
      order_items_order: {
        select: {
          order_item_id: true,
          menu_item_id: true,
          item_name: true,
          quantity: true,
          notes: true,
          order_item_modifiers_order_item: {
            select: {
              order_item_modifier_id: true,
              modifier_id: true,
              modifier_name: true,
            },
          },
        },
      },
    },
  },
} satisfies Prisma.KitchenTicketInclude;

type TicketWithOrderItems = Prisma.KitchenTicketGetPayload<{
  include: typeof includeOrderItems;
}>;

function withOrderItems(ticket: TicketWithOrderItems) {
  const { order, ...rest } = ticket;
  return {
    ...rest,
    order_items: order.order_items_order.map(
      ({ order_item_modifiers_order_item, ...item }) => ({
        ...item,
        modifiers: order_item_modifiers_order_item,
      }),
    ),
  };
}

@Injectable()
export class KitchenTicketRepository {
  constructor(private readonly prisma: PrismaService) {}

  async create(
    dto: CreateKitchenTicketDTO,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.kitchenTicket.create({
      data: dto,
    });
  }

  async findOne(
    kitchenTicketId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.kitchenTicket.findUnique({
      where: {
        kitchen_ticket_id: kitchenTicketId,
      },
    });
  }

  async findOneWithItems(
    kitchenTicketId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    const ticket = await tx.kitchenTicket.findUnique({
      where: { kitchen_ticket_id: kitchenTicketId },
      include: includeOrderItems,
    });
    return ticket ? withOrderItems(ticket) : null;
  }

  async findAll(
    skip: number,
    take: number,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    const ticketsQuery = tx.kitchenTicket.findMany({
      skip,
      take,
      orderBy: [{ created_at: 'desc' }, { kitchen_ticket_id: 'asc' }],
      include: includeOrderItems,
    });
    const totalQuery = tx.kitchenTicket.count();

    const [kitchenTickets, total] =
      '$transaction' in tx
        ? await tx.$transaction([ticketsQuery, totalQuery], {
            isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead,
          })
        : await Promise.all([ticketsQuery, totalQuery]);

    return { kitchenTickets: kitchenTickets.map(withOrderItems), total };
  }

  async findMany(tx: Prisma.TransactionClient | PrismaService = this.prisma) {
    const today = new Date().toLocaleDateString('en-CA', {
      timeZone: 'Asia/Manila',
    });
    const startOfDay = new Date(`${today}T00:00:00+08:00`);
    const startOfTomorrow = new Date(startOfDay);
    startOfTomorrow.setUTCDate(startOfTomorrow.getUTCDate() + 1);

    const tickets = await tx.kitchenTicket.findMany({
      where: {
        created_at: {
          gte: startOfDay,
          lt: startOfTomorrow,
        },
      },
      include: includeOrderItems,
    });
    return tickets.map(withOrderItems);
  }

  async findManyByPreparer(
    preparerId: string,
    excludeHandedOver = true,
    onlyToday = true,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    const today = new Date().toLocaleDateString('en-CA', {
      timeZone: 'Asia/Manila',
    });
    const startOfDay = new Date(`${today}T00:00:00+08:00`);
    const startOfTomorrow = new Date(startOfDay);
    startOfTomorrow.setUTCDate(startOfTomorrow.getUTCDate() + 1);

    const tickets = await tx.kitchenTicket.findMany({
      where: {
        preparer_id: preparerId,
        ...(onlyToday
          ? { created_at: { gte: startOfDay, lt: startOfTomorrow } }
          : {}),
        ...(excludeHandedOver
          ? { status: { not: KitchenTicketStatus.HANDED_OVER } }
          : {}),
      },
      include: includeOrderItems,
    });
    return tickets.map(withOrderItems);
  }

  async findManyByChecker(
    checkerId: string,
    excludeHandedOver = true,
    onlyToday = true,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    const today = new Date().toLocaleDateString('en-CA', {
      timeZone: 'Asia/Manila',
    });
    const startOfDay = new Date(`${today}T00:00:00+08:00`);
    const startOfTomorrow = new Date(startOfDay);
    startOfTomorrow.setUTCDate(startOfTomorrow.getUTCDate() + 1);

    const tickets = await tx.kitchenTicket.findMany({
      where: {
        checker_id: checkerId,
        ...(onlyToday
          ? { created_at: { gte: startOfDay, lt: startOfTomorrow } }
          : {}),
        ...(excludeHandedOver
          ? { status: { not: KitchenTicketStatus.HANDED_OVER } }
          : {}),
      },
      include: includeOrderItems,
    });
    return tickets.map(withOrderItems);
  }

  async updateStatus(
    kitchenTicketId: string,
    newStatus: KitchenTicketStatus,
    expectedStatus: KitchenTicketStatus,
    extraData: Prisma.KitchenTicketUpdateInput = {},
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.kitchenTicket.update({
      where: {
        kitchen_ticket_id: kitchenTicketId,
        status: expectedStatus,
      },
      data: {
        ...extraData,
        status: newStatus,
        modified_at: new Date(),
      },
    });
  }

  async prepare(
    kitchenTicketId: string,
    preparerId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    const prepareTicket = async (client: Prisma.TransactionClient) => {
      await this.updateStatus(
        kitchenTicketId,
        KitchenTicketStatus.PREPARING,
        KitchenTicketStatus.ACKNOWLEDGED,
        { preparation_started_at: new Date() },
        client,
      );

      return this.assignPreparer(kitchenTicketId, preparerId, client);
    };

    return '$transaction' in tx
      ? tx.$transaction(prepareTicket)
      : prepareTicket(tx);
  }

  async assignPreparer(
    kitchenTicketId: string,
    preparerId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.kitchenTicket.update({
      where: {
        kitchen_ticket_id: kitchenTicketId,
        preparer_id: null,
      },
      data: {
        preparer_id: preparerId,
      },
    });
  }

  async assignChecker(
    kitchenTicketId: string,
    checkerId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.kitchenTicket.update({
      where: {
        kitchen_ticket_id: kitchenTicketId,
        checker_id: null,
      },
      data: {
        checker_id: checkerId,
      },
    });
  }
}
