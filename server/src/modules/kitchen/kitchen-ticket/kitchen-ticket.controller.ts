import {
  Body,
  Controller,
  Get,
  MessageEvent,
  Param,
  ParseUUIDPipe,
  Patch,
  Query,
  Sse,
  UseGuards,
} from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { Roles } from '../../../shared/decorators/roles.decorator';
import { PaginationDTO } from '../../../shared/dto/pagination.dto';
import { RolesGuard } from '../../../shared/guards/roles.guard';
import { Authenticated } from '../../auth/auth.guard';
import {
  AssignKitchenTicketCheckerDocs,
  AssignKitchenTicketPreparerDocs,
  FindAllKitchenTicketsDocs,
  FindKitchenTicketsByCheckerDocs,
  FindKitchenTicketsByPreparerDocs,
  FindOneKitchenTicketDocs,
  FindTodaysKitchenTicketsDocs,
  KitchenTicketDocs,
  StreamTodaysKitchenTicketsDocs,
} from './docs/kitchen-ticket.docs';
import { FindKitchenTicketsDTO } from './dto/find-kitchen-tickets.dto';
import { KitchenTicketService } from './kitchen-ticket.service';
import { Audit, fromParam } from '../../../shared/audit/audit.decorator';
import { Observable } from 'rxjs';

@Controller('kitchen-ticket')
@KitchenTicketDocs()
@UseGuards(Authenticated, RolesGuard)
@Roles(
  UserRole.SUPERADMIN,
  UserRole.MANAGER,
  UserRole.SUPERVISOR,
  UserRole.KITCHEN_STAFF,
  UserRole.KITCHEN_HEAD,
)
export class KitchenTicketController {
  constructor(private readonly kitchenTicketService: KitchenTicketService) {}

  @Get()
  @FindAllKitchenTicketsDocs()
  @Roles(
    UserRole.SUPERADMIN,
    UserRole.MANAGER,
    UserRole.KITCHEN_HEAD,
    UserRole.SUPERVISOR,
  )
  async findAll(@Query() query: PaginationDTO) {
    return this.kitchenTicketService.findAll(
      (query.page - 1) * query.limit,
      query.limit,
    );
  }

  @Get('today')
  @FindTodaysKitchenTicketsDocs()
  async findMany() {
    return this.kitchenTicketService.findMany();
  }

  @Sse('today/stream')
  @StreamTodaysKitchenTicketsDocs()
  stream(): Observable<MessageEvent> {
    return this.kitchenTicketService.stream();
  }

  @Get('preparer/:preparerId')
  @FindKitchenTicketsByPreparerDocs()
  async findManyByPreparer(
    @Param('preparerId', ParseUUIDPipe) preparerId: string,
    @Query() query: FindKitchenTicketsDTO,
  ) {
    return this.kitchenTicketService.findManyByPreparer(
      preparerId,
      query.excludeHandedOver,
      query.onlyToday,
    );
  }

  @Get('checker/:checkerId')
  @FindKitchenTicketsByCheckerDocs()
  async findManyByChecker(
    @Param('checkerId', ParseUUIDPipe) checkerId: string,
    @Query() query: FindKitchenTicketsDTO,
  ) {
    return this.kitchenTicketService.findManyByChecker(
      checkerId,
      query.excludeHandedOver,
      query.onlyToday,
    );
  }

  @Get(':id')
  @FindOneKitchenTicketDocs()
  async findOne(@Param('id', ParseUUIDPipe) kitchenTicketId: string) {
    return this.kitchenTicketService.findOneWithItems(kitchenTicketId);
  }

  @Patch(':id/preparer')
  @Audit({
    action: 'KITCHEN_TICKET_PREPARER_ASSIGNED',
    snapshot: 'update',
    entity: 'kitchen_tickets',
    id: fromParam('id'),
  })
  @AssignKitchenTicketPreparerDocs()
  async claimPerparer(
    @Param('id', ParseUUIDPipe) kitchenTicketId: string,
    @Body('preparer_id', ParseUUIDPipe) preparerId: string,
  ) {
    return this.kitchenTicketService.assignPreparer(
      kitchenTicketId,
      preparerId,
    );
  }

  @Patch(':id/checker')
  @Audit({
    action: 'KITCHEN_TICKET_CHECKER_ASSIGNED',
    snapshot: 'update',
    entity: 'kitchen_tickets',
    id: fromParam('id'),
  })
  @AssignKitchenTicketCheckerDocs()
  @Roles(
    UserRole.MANAGER,
    UserRole.SUPERADMIN,
    UserRole.SUPERVISOR,
    UserRole.KITCHEN_HEAD,
  )
  async claimChecker(
    @Param('id', ParseUUIDPipe) kitchenTicketId: string,
    @Body('checker_id', ParseUUIDPipe) checkerId: string,
  ) {
    return this.kitchenTicketService.assignChecker(kitchenTicketId, checkerId);
  }
}
