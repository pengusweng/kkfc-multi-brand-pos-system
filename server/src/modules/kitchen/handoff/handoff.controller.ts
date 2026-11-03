import {
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Query,
  UseGuards,
} from '@nestjs/common';
import { HandoffService } from './handoff.service';
import { Authenticated } from '../../auth/auth.guard';
import { RolesGuard } from '../../../shared/guards/roles.guard';
import { Roles } from '../../../shared/decorators/roles.decorator';
import { UserRole } from '@prisma/client';
import { PaginationDTO } from '../../../shared/dto/pagination.dto';

@Controller('handoff')
@UseGuards(Authenticated, RolesGuard)
@Roles(
  UserRole.SUPERADMIN,
  UserRole.MANAGER,
  UserRole.KITCHEN_STAFF,
  UserRole.KITCHEN_HEAD,
  UserRole.CASHIER_STAFF,
)
export class HandoffController {
  constructor(private readonly handoffService: HandoffService) {}

  @Get()
  @Roles(UserRole.SUPERADMIN, UserRole.MANAGER, UserRole.KITCHEN_HEAD)
  async findAll(@Query() query: PaginationDTO) {
    return this.handoffService.findAll(
      (query.page - 1) * query.limit,
      query.limit,
    );
  }

  @Get(':handoffId')
  async findOne(@Param('handoffId', ParseUUIDPipe) handoffId: string) {
    return this.handoffService.findOne(handoffId);
  }

  @Get('/kitchen-ticket/:id')
  async findOneByKitchenTicket(
    @Param('kitchenTicketId', ParseUUIDPipe) kitchenTicketId: string,
  ) {
    return this.handoffService.findOneByKitchenTicket(kitchenTicketId);
  }

  @Get('/actor/:actorId')
  @Roles(UserRole.SUPERADMIN, UserRole.MANAGER, UserRole.KITCHEN_HEAD)
  async findManyByActor(
    @Param('actorId', ParseUUIDPipe) actorId: string,
    @Query() query: PaginationDTO,
  ) {
    return this.handoffService.findManyByActor(
      actorId,
      (query.page - 1) * query.limit,
      query.limit,
    );
  }
}
