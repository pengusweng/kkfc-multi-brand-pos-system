import { Controller } from '@nestjs/common';
import { KitchenFulfillmentService } from './kitchen-fulfillment.service';

@Controller('kitchen-fulfillment')
export class KitchenFulfillmentController {
  constructor(
    private readonly kitchenFulfillmentService: KitchenFulfillmentService,
  ) {}
}
