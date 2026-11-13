import {
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  UseGuards,
} from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { Roles } from '../../../shared/decorators/roles.decorator';
import { RolesGuard } from '../../../shared/guards/roles.guard';
import { Authenticated } from '../../auth/auth.guard';
import {
  FindOneOrderItemQcRejectionDocs,
  FindOrderItemQcRejectionsByAttemptDocs,
  FindOrderItemQcRejectionsByOrderItemDocs,
  OrderItemQcRejectionDocs,
} from './docs/order-item-qc-rejection.docs';
import { OrderItemQcRejectionService } from './order-item-qc-rejection.service';

@Controller('order-item-qc-rejection')
@OrderItemQcRejectionDocs()
@UseGuards(Authenticated, RolesGuard)
@Roles(
  UserRole.SUPERADMIN,
  UserRole.SUPERVISOR,
  UserRole.KITCHEN_HEAD,
  UserRole.KITCHEN_STAFF,
)
export class OrderItemQcRejectionController {
  constructor(
    private readonly orderItemQcRejectionService: OrderItemQcRejectionService,
  ) {}

  @Get('attempt/:attemptId')
  @FindOrderItemQcRejectionsByAttemptDocs()
  findManyByAttemptId(@Param('attemptId', ParseUUIDPipe) attemptId: string) {
    return this.orderItemQcRejectionService.findManyByAttemptId(attemptId);
  }

  @Get('order-item/:orderItemId')
  @FindOrderItemQcRejectionsByOrderItemDocs()
  findManyByOrderItemId(
    @Param('orderItemId', ParseUUIDPipe) orderItemId: string,
  ) {
    return this.orderItemQcRejectionService.findManyByOrderItemId(orderItemId);
  }

  @Get(':id')
  @FindOneOrderItemQcRejectionDocs()
  findOne(@Param('id', ParseUUIDPipe) rejectionId: string) {
    return this.orderItemQcRejectionService.findOne(rejectionId);
  }
}
