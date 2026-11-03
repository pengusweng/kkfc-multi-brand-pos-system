import { Injectable } from '@nestjs/common';
import { InventoryItemsRepository } from '../../inventory/inventory-items/inventory-items.repository';
import { InventoryItemsService } from '../../inventory/inventory-items/inventory-items.service';
import { OrderItemsRepository } from '../../orders/order-items/order-items.repository';
import { OrderItemsService } from '../../orders/order-items/order-items.service';
import { OrdersRepository } from '../../orders/orders/orders.repository';
import { OrdersService } from '../../orders/orders/orders.service';
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

@Injectable()
export class KitchenFulfillmentService {
  constructor(
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
    private readonly inventoryItemsService: InventoryItemsService,
    private readonly inventoryItemsRepository: InventoryItemsRepository,
  ) {}
}
