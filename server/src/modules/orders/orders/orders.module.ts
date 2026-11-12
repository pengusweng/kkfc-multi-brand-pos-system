import { OrderItemsModule } from '../order-items/order-items.module';
import { Module } from '@nestjs/common';
import { KitchenTicketChangesModule } from '../../kitchen/kitchen-ticket/kitchen-ticket-changes.module';
import { OrdersController } from './orders.controller';
import { OrdersRepository } from './orders.repository';
import { OrdersService } from './orders.service';

@Module({
  imports: [OrderItemsModule, KitchenTicketChangesModule],
  controllers: [OrdersController],
  providers: [OrdersService, OrdersRepository],
  exports: [OrdersService, OrdersRepository],
})
export class OrdersModule {}
