import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import { CreateHandoffDTO } from './dto/create-handoff.dto';
import { Prisma } from '@prisma/client';

@Injectable()
export class HandoffRepository {
  constructor(private readonly prisma: PrismaService) {}

  async create(
    kitchenTicketId: string,
    actorId: string,
    dto: CreateHandoffDTO,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.handoff.create({
      data: {
        kitchen_ticket_id: kitchenTicketId,
        actor_id: actorId,
        ...dto,
      },
    });
  }

  async findOne(
    handoffId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.handoff.findUnique({
      where: { handoff_id: handoffId },
    });
  }

  async findOneByKitchenTicket(
    kitchenTicketId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.handoff.findUnique({
      where: { kitchen_ticket_id: kitchenTicketId },
    });
  }

  async findManyByActor(
    actorId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.handoff.findMany({
      where: { actor_id: actorId },
    });
  }

  async findAll(
    skip: number,
    take: number,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    const handoffsQuery = tx.handoff.findMany({
      skip,
      take,
      orderBy: [{ created_at: 'desc' }, { handoff_id: 'asc' }],
    });
    const totalQuery = tx.handoff.count();

    const [handoffs, total] =
      '$transaction' in tx
        ? await tx.$transaction([handoffsQuery, totalQuery], {
            isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead,
          })
        : await Promise.all([handoffsQuery, totalQuery]);

    return { handoffs, total };
  }
}
