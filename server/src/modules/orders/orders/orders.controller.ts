import {
  OrdersDocs,
  CreateOrderDocs,
  VerifyOrderDocs,
  ConfirmOrderDocs,
  CancelOrderDocs,
  FindOrdersDocs,
  FindOneOrderDocs,
} from './docs/orders.docs';
import {
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { UserRole } from '@prisma/client';
import {
  Authenticated,
  type AuthenticatedRequest,
} from '../../auth/auth.guard';
import { RolesGuard } from '../../../shared/guards/roles.guard';
import { Roles } from '../../../shared/decorators/roles.decorator';
import {
  CreateOrderDTO,
  ConfirmOrderDTO,
  CancelOrderDTO,
} from './dto/order.dto';
import { FindOrdersDTO } from './dto/find-orders.dto';
import { KitchenTicketChanges } from '../../kitchen/kitchen-ticket/kitchen-ticket-changes.service';
import { OrdersService } from './orders.service';
import {
  Audit,
  fromParam,
  fromResult,
  NoAudit,
} from '../../../shared/audit/audit.decorator';

@Controller('brands/:brandId/orders')
@OrdersDocs()
@UseGuards(Authenticated, RolesGuard)
@Roles(
  UserRole.SUPERVISOR,
  UserRole.CASHIER_STAFF,
  UserRole.MANAGER,
  UserRole.SUPERADMIN,
)
export class OrdersController {
  constructor(
    private readonly orders: OrdersService,
    private readonly kitchenTicketChanges: KitchenTicketChanges,
  ) {}

  @FindOrdersDocs()
  @Get()
  findAll(
    @Param('brandId', ParseUUIDPipe) brandId: string,
    @Query() query: FindOrdersDTO,
  ) {
    return this.orders.findAll(brandId, query);
  }

  @FindOneOrderDocs()
  @Get(':orderId')
  @Roles(
    UserRole.CASHIER_STAFF,
    UserRole.MANAGER,
    UserRole.SUPERVISOR,
    UserRole.SUPERADMIN,
    UserRole.KITCHEN_HEAD,
    UserRole.KITCHEN_STAFF,
  )
  findOne(
    @Param('brandId', ParseUUIDPipe) brandId: string,
    @Param('orderId', ParseUUIDPipe) orderId: string,
  ) {
    return this.orders.findOne(brandId, orderId);
  }

  @CreateOrderDocs()
  @Post()
  @Audit({
    action: 'ORDER_CREATED',
    snapshot: 'create',
    entity: 'orders',
    id: fromResult('order_id'),
  })
  create(
    @Param('brandId', ParseUUIDPipe) brandId: string,
    @Body() dto: CreateOrderDTO,
    @Req() req: AuthenticatedRequest,
  ) {
    return this.orders.create(brandId, req.session.user.user_id, dto);
  }

  @VerifyOrderDocs()
  @Post(':orderId/verify')
  @NoAudit('read-only price and availability check; writes nothing')
  @HttpCode(200)
  verify(
    @Param('brandId', ParseUUIDPipe) brandId: string,
    @Param('orderId', ParseUUIDPipe) orderId: string,
    @Body() dto: ConfirmOrderDTO,
  ) {
    return this.orders.verify(brandId, orderId, dto);
  }

  @ConfirmOrderDocs()
  @Post(':orderId/confirm')
  @Audit({
    action: 'ORDER_CONFIRMED',
    snapshot: 'update',
    entity: 'orders',
    id: fromParam('orderId'),
  })
  @HttpCode(200)
  async confirm(
    @Param('brandId', ParseUUIDPipe) brandId: string,
    @Param('orderId', ParseUUIDPipe) orderId: string,
    @Body() dto: ConfirmOrderDTO,
    @Req() req: AuthenticatedRequest,
  ) {
    const order = await this.orders.confirm(
      brandId,
      orderId,
      req.session.user.user_id,
      dto,
    );
    // Confirming creates the kitchen ticket; the transaction has committed here.
    this.kitchenTicketChanges.notify();
    return order;
  }

  @CancelOrderDocs()
  @Post(':orderId/cancel')
  @Audit({
    action: 'ORDER_CANCELLED',
    snapshot: 'update',
    entity: 'orders',
    id: fromParam('orderId'),
  })
  @HttpCode(200)
  cancel(
    @Param('brandId', ParseUUIDPipe) brandId: string,
    @Param('orderId', ParseUUIDPipe) orderId: string,
    @Body() dto: CancelOrderDTO,
    @Req() req: AuthenticatedRequest,
  ) {
    return this.orders.cancelDraft(
      brandId,
      orderId,
      req.session.user.user_id,
      dto,
    );
  }
}
