import {
  BadRequestException,
  ConflictException,
  Injectable,
  Logger,
} from '@nestjs/common';
import {
  KitchenTicketQcStatus,
  KitchenTicketStatus,
  Prisma,
} from '@prisma/client';
import { assertExists } from '../../../shared/assertions/assert-exists';
import { CreateOrderItemQcRejectionDTO } from './dto/create-order-item-qc-rejection.dto';
import { OrderItemQcRejectionRepository } from './order-item-qc-rejection.repository';

@Injectable()
export class OrderItemQcRejectionService {
  private readonly logger = new Logger(OrderItemQcRejectionService.name);

  constructor(
    private readonly orderItemQcRejectionRepository: OrderItemQcRejectionRepository,
  ) {}

  async create(
    attemptId: string,
    orderItemId: string,
    dto: CreateOrderItemQcRejectionDTO,
    tx?: Prisma.TransactionClient,
  ) {
    this.logger.debug(
      `Creating QC rejection for attempt ${attemptId}, order item ${orderItemId}`,
    );

    const attempt = await this.orderItemQcRejectionRepository.findAttempt(
      attemptId,
      tx,
    );
    assertExists(attempt, 'KitchenTicketQcAttempt', attemptId, this.logger);

    if (
      attempt.status !== KitchenTicketQcStatus.IN_PROGRESS ||
      attempt.kitchen_ticket.status !== KitchenTicketStatus.CHECKING
    ) {
      throw new ConflictException({
        code: 'UNABLE_TO_CREATE_QC_REJECTION',
        message:
          'Rejections require an in-progress QC attempt and a ticket being checked.',
      });
    }

    const orderItem = await this.orderItemQcRejectionRepository.findOrderItem(
      orderItemId,
      tx,
    );
    assertExists(orderItem, 'OrderItem', orderItemId, this.logger);

    if (orderItem.order_id !== attempt.kitchen_ticket.order_id) {
      throw new BadRequestException({
        code: 'ORDER_ITEM_NOT_IN_TICKET',
        message: 'The order item does not belong to the QC attempt ticket.',
      });
    }

    if (dto.portion_number > orderItem.quantity) {
      throw new BadRequestException({
        code: 'INVALID_PORTION_NUMBER',
        message: 'Portion number must not exceed the order item quantity.',
      });
    }

    const rejection = await this.orderItemQcRejectionRepository.create(
      attemptId,
      orderItemId,
      dto,
      tx,
    );

    this.logger.log(
      `Created order item QC rejection ${rejection.rejection_id}`,
    );
    return rejection;
  }

  async findOne(rejectionId: string) {
    this.logger.debug(`Finding order item QC rejection ${rejectionId}`);

    const rejection =
      await this.orderItemQcRejectionRepository.findOne(rejectionId);
    assertExists(rejection, 'OrderItemQcRejection', rejectionId, this.logger);

    this.logger.log(`Found order item QC rejection ${rejection.rejection_id}`);
    return rejection;
  }

  async findManyByAttemptId(attemptId: string) {
    this.logger.debug(
      `Listing order item QC rejections for attempt ${attemptId}`,
    );

    const rejections =
      await this.orderItemQcRejectionRepository.findManyByAttemptId(attemptId);

    this.logger.log(
      `Listed order item QC rejections for attempt ${attemptId}: returned=${rejections.length}`,
    );
    return rejections;
  }

  async findManyByOrderItemId(orderItemId: string) {
    this.logger.debug(`Listing QC rejections for order item ${orderItemId}`);

    const rejections =
      await this.orderItemQcRejectionRepository.findManyByOrderItemId(
        orderItemId,
      );

    this.logger.log(
      `Listed QC rejections for order item ${orderItemId}: returned=${rejections.length}`,
    );
    return rejections;
  }
}
