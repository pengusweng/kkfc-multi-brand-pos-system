import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { Authenticated } from '../../auth/auth.guard';
import { Roles } from '../../../shared/decorators/roles.decorator';
import { RolesGuard } from '../../../shared/guards/roles.guard';
import { FindAllOrdersDocs } from './docs/orders.docs';
import { FindAllOrdersDTO } from './dto/find-all-orders.dto';
import { OrdersService } from './orders.service';

/**
 * The back-office view of orders across every brand. Order actions stay on
 * the brand-scoped OrdersController; this is read-only.
 */
@Controller('orders')
@UseGuards(Authenticated, RolesGuard)
@Roles(UserRole.SUPERVISOR, UserRole.CASHIER_STAFF, UserRole.SUPERADMIN)
export class AllOrdersController {
  constructor(private readonly orders: OrdersService) {}

  @FindAllOrdersDocs()
  @Get()
  findAll(@Query() query: FindAllOrdersDTO) {
    return this.orders.findOverview(query);
  }
}
