import {
  Body,
  Controller,
  HttpCode,
  Param,
  ParseUUIDPipe,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Roles } from '../../../shared/decorators/roles.decorator';
import { RolesGuard } from '../../../shared/guards/roles.guard';
import {
  Authenticated,
  type AuthenticatedRequest,
} from '../../auth/auth.guard';
import { CancelOrderDTO } from '../../orders/orders/dto/order.dto';
import { KitchenFulfillmentService } from './kitchen-fulfillment.service';

@Controller('kitchen-fulfillment')
@ApiTags('Kitchen fulfillment')
@ApiBearerAuth()
@UseGuards(Authenticated, RolesGuard)
export class KitchenFulfillmentController {
  constructor(
    private readonly kitchenFulfillmentService: KitchenFulfillmentService,
  ) {}

  @Post('brands/:brandId/orders/:orderId/cancel')
  @HttpCode(200)
  @Roles(UserRole.CASHIER_STAFF, UserRole.MANAGER, UserRole.SUPERADMIN)
  @ApiOperation({
    summary: 'Cancel an order and its kitchen ticket',
    description:
      'Cancels both records in one transaction. Requires a kitchen ticket and a nonblank reason. Completed orders and handed-over tickets cannot be cancelled.',
  })
  async cancel(
    @Param('brandId', ParseUUIDPipe) brandId: string,
    @Param('orderId', ParseUUIDPipe) orderId: string,
    @Body() dto: CancelOrderDTO,
    @Req() req: AuthenticatedRequest,
  ) {
    return this.kitchenFulfillmentService.cancel(
      brandId,
      orderId,
      req.session.user.user_id,
      dto,
    );
  }
}
