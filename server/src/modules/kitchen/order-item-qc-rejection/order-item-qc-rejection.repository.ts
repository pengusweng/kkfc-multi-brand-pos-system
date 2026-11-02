import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import { CreateOrderItemQcRejectionDTO } from './dto/create-order-item-qc-rejection.dto';
import { Prisma } from '@prisma/client';

@Injectable()
export class OrderItemQcRejectionRepository {
  constructor(private readonly prisma: PrismaService) {}

  async create(
    attemptId: string,
    orderItemId: string,
    dto: CreateOrderItemQcRejectionDTO,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.orderItemQcRejection.create({
      data: {
        qc_attempt_id: attemptId,
        order_item_id: orderItemId,
        ...dto,
      },
    });
  }

  async findOne(
    rejectionId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.orderItemQcRejection.findUnique({
      where: { rejection_id: rejectionId },
    });
  }

  async findManyByAttemptId(
    attemptId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.orderItemQcRejection.findMany({
      where: { qc_attempt_id: attemptId },
    });
  }

  async findManyByOrderItemId(
    orderItemId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.orderItemQcRejection.findMany({
      where: { order_item_id: orderItemId },
    });
  }
}
