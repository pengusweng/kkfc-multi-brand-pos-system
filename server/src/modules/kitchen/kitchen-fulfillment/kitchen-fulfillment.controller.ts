import {
  Body,
  Controller,
  HttpCode,
  Param,
  ParseUUIDPipe,
  Post,
  Req,
  UploadedFiles,
  UseGuards,
  UseInterceptors,
  BadRequestException,
} from '@nestjs/common';
import { FilesInterceptor } from '@nestjs/platform-express';
import {
  AssetsService,
  type AssetUpload,
  MAX_ASSET_BYTES,
} from '../../assets/assets.service';
import {
  KitchenFulfillmentDocs,
  AcknowledgeDocs,
  PrepareDocs,
  ForCheckingDocs,
  CheckDocs,
  PassQcDocs,
  RejectQcDocs,
  HandOverDocs,
  CancelDocs,
} from './docs/kitchen-fulfillment.docs';
import {
  Authenticated,
  type AuthenticatedRequest,
} from '../../auth/auth.guard';
import { CancelOrderDTO } from '../../orders/orders/dto/order.dto';
import { KitchenFulfillmentService } from './kitchen-fulfillment.service';
import { HandOverDTO } from './dto/hand-over.dto';
import { RejectQcAttemptDTO } from './dto/reject-qc-attempt.dto';
import { RolesGuard } from '../../../shared/guards/roles.guard';
import { Roles } from '../../../shared/decorators/roles.decorator';
import { UserRole } from '@prisma/client';
import { Audit, fromParam } from '../../../shared/audit/audit.decorator';

@Controller('kitchen-fulfillment')
@KitchenFulfillmentDocs()
@UseGuards(Authenticated, RolesGuard)
@Roles(
  UserRole.SUPERADMIN,
  UserRole.MANAGER,
  UserRole.SUPERVISOR,
  UserRole.KITCHEN_STAFF,
  UserRole.KITCHEN_HEAD,
)
export class KitchenFulfillmentController {
  constructor(
    private readonly kitchenFulfillmentService: KitchenFulfillmentService,
    private readonly assetsService: AssetsService,
  ) {}

  @Post(':kitchenTicketId/acknowledge')
  @Audit({
    action: 'KITCHEN_TICKET_ACKNOWLEDGED',
    snapshot: 'update',
    entity: 'kitchen_tickets',
    id: fromParam('kitchenTicketId'),
  })
  @HttpCode(200)
  @AcknowledgeDocs()
  async acknowledge(
    @Param('kitchenTicketId', ParseUUIDPipe) kitchenTicketId: string,
  ) {
    return this.kitchenFulfillmentService.acknowledge(kitchenTicketId);
  }

  @Post(':kitchenTicketId/prepare')
  @Audit({
    action: 'KITCHEN_TICKET_PREPARATION_STARTED',
    snapshot: 'update',
    entity: 'kitchen_tickets',
    id: fromParam('kitchenTicketId'),
  })
  @HttpCode(200)
  @PrepareDocs()
  async prepare(
    @Param('kitchenTicketId', ParseUUIDPipe) kitchenTicketId: string,
    @Req() req: AuthenticatedRequest,
  ) {
    return this.kitchenFulfillmentService.prepare(
      kitchenTicketId,
      req.session.user.user_id,
    );
  }

  @Post(':kitchenTicketId/for-checking')
  @Audit({
    action: 'KITCHEN_TICKET_SENT_FOR_CHECKING',
    snapshot: 'update',
    entity: 'kitchen_tickets',
    id: fromParam('kitchenTicketId'),
  })
  @HttpCode(200)
  @ForCheckingDocs()
  async forChecking(
    @Param('kitchenTicketId', ParseUUIDPipe) kitchenTicketId: string,
    @Req() req: AuthenticatedRequest,
  ) {
    return this.kitchenFulfillmentService.forChecking(
      kitchenTicketId,
      req.session.user.user_id,
    );
  }

  @Post(':kitchenTicketId/check')
  @Audit({
    action: 'KITCHEN_TICKET_CHECK_STARTED',
    snapshot: 'update',
    entity: 'kitchen_tickets',
    id: fromParam('kitchenTicketId'),
  })
  @HttpCode(200)
  @CheckDocs()
  @Roles(
    UserRole.SUPERADMIN,
    UserRole.MANAGER,
    UserRole.KITCHEN_HEAD,
    UserRole.SUPERVISOR,
  )
  async check(
    @Param('kitchenTicketId', ParseUUIDPipe) kitchenTicketId: string,
    @Req() req: AuthenticatedRequest,
  ) {
    return this.kitchenFulfillmentService.check(
      kitchenTicketId,
      req.session.user.user_id,
    );
  }

  @Post('qc-attempts/:attemptId/pass')
  @Audit({
    action: 'KITCHEN_QC_PASSED',
    snapshot: 'update',
    entity: 'kitchen_ticket_qc_attempts',
    id: fromParam('attemptId'),
  })
  @HttpCode(200)
  @PassQcDocs()
  @Roles(
    UserRole.SUPERADMIN,
    UserRole.MANAGER,
    UserRole.KITCHEN_HEAD,
    UserRole.SUPERVISOR,
  )
  async passQCAttempt(
    @Param('attemptId', ParseUUIDPipe) attemptId: string,
    @Req() req: AuthenticatedRequest,
  ) {
    return this.kitchenFulfillmentService.passQCAttempt(
      attemptId,
      req.session.user.user_id,
    );
  }

  @Post('qc-attempts/:attemptId/reject')
  @Audit({
    action: 'KITCHEN_QC_REJECTED',
    snapshot: 'update',
    entity: 'kitchen_ticket_qc_attempts',
    id: fromParam('attemptId'),
  })
  @HttpCode(200)
  @RejectQcDocs()
  @Roles(
    UserRole.SUPERADMIN,
    UserRole.MANAGER,
    UserRole.KITCHEN_HEAD,
    UserRole.SUPERVISOR,
  )
  async rejectQcAttempt(
    @Param('attemptId', ParseUUIDPipe) attemptId: string,
    @Body() dto: RejectQcAttemptDTO,
    @Req() req: AuthenticatedRequest,
  ) {
    return this.kitchenFulfillmentService.rejectQcAttempt(
      attemptId,
      req.session.user.user_id,
      dto,
    );
  }

  @Post(':kitchenTicketId/hand-over')
  @Audit({
    action: 'KITCHEN_TICKET_HANDED_OVER',
    snapshot: 'update',
    entity: 'kitchen_tickets',
    id: fromParam('kitchenTicketId'),
  })
  @HttpCode(200)
  @HandOverDocs()
  @UseInterceptors(
    FilesInterceptor('files', 5, {
      limits: { fileSize: MAX_ASSET_BYTES, files: 5 },
    }),
  )
  async handOver(
    @Param('kitchenTicketId', ParseUUIDPipe) kitchenTicketId: string,
    @Body() dto: HandOverDTO,
    @UploadedFiles() files: AssetUpload[] | undefined,
    @Req() req: AuthenticatedRequest,
  ) {
    const keys = dto.img_keys ?? [];
    if (keys.length + (files?.length ?? 0) > 5) {
      throw new BadRequestException({
        code: 'TOO_MANY_HANDOFF_IMAGES',
        message: 'A handover can have at most 5 images.',
      });
    }
    for (const file of files ?? []) {
      const asset = await this.assetsService.upload(
        req.session.user.user_id,
        file,
      );
      keys.push(asset.key);
    }
    return this.kitchenFulfillmentService.handOver(
      kitchenTicketId,
      req.session.user.user_id,
      keys.length === 0 ? undefined : { img_keys: keys },
    );
  }

  @Post('brands/:brandId/orders/:orderId/cancel')
  // Same action as the draft cancel so one filter finds every cancellation.
  @Audit({
    action: 'ORDER_CANCELLED',
    snapshot: 'update',
    entity: 'orders',
    id: fromParam('orderId'),
  })
  @HttpCode(200)
  @CancelDocs()
  @Roles(
    UserRole.SUPERADMIN,
    UserRole.MANAGER,
    UserRole.KITCHEN_HEAD,
    UserRole.SUPERVISOR,
  )
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
