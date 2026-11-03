import { Module } from '@nestjs/common';
import { AssetsModule } from '../../assets/assets.module';
import { InventoryItemsModule } from '../../inventory/inventory-items/inventory-items.module';
import { OrderItemsModule } from '../../orders/order-items/order-items.module';
import { OrdersModule } from '../../orders/orders/orders.module';
import { UsersModule } from '../../users/users.module';
import { HandoffModule } from '../handoff/handoff.module';
import { KitchenQcModule } from '../kitchen-qc/kitchen-qc.module';
import { KitchenTicketModule } from '../kitchen-ticket/kitchen-ticket.module';
import { OrderItemQcRejectionModule } from '../order-item-qc-rejection/order-item-qc-rejection.module';
import { KitchenFulfillmentController } from './kitchen-fulfillment.controller';
import { KitchenFulfillmentService } from './kitchen-fulfillment.service';

@Module({
  imports: [
    AssetsModule,
    KitchenTicketModule,
    KitchenQcModule,
    OrderItemQcRejectionModule,
    HandoffModule,
    UsersModule,
    OrdersModule,
    OrderItemsModule,
    InventoryItemsModule,
  ],
  controllers: [KitchenFulfillmentController],
  providers: [KitchenFulfillmentService],
  exports: [KitchenFulfillmentService],
})
export class KitchenFulfillmentModule {}
