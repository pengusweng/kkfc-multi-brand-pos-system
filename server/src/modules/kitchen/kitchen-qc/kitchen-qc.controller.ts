import {
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Query,
  UseGuards,
} from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { Roles } from '../../../shared/decorators/roles.decorator';
import { PaginationDTO } from '../../../shared/dto/pagination.dto';
import { RolesGuard } from '../../../shared/guards/roles.guard';
import { Authenticated } from '../../auth/auth.guard';
import {
  FindAllKitchenQcDocs,
  FindKitchenQcByCheckerDocs,
  FindKitchenQcByTicketDocs,
  FindLatestKitchenQcDocs,
  FindOneKitchenQcDocs,
  KitchenQcDocs,
} from './docs/kitchen-qc.docs';
import { FindKitchenQcDTO } from './dto/find-kitchen-qc.dto';
import { KitchenQcService } from './kitchen-qc.service';

@Controller('kitchen-qc')
@KitchenQcDocs()
@UseGuards(Authenticated, RolesGuard)
@Roles(
  UserRole.SUPERADMIN,
  UserRole.MANAGER,
  UserRole.SUPERVISOR,
  UserRole.KITCHEN_HEAD,
  UserRole.KITCHEN_STAFF,
)
export class KitchenQcController {
  constructor(private readonly kitchenQcService: KitchenQcService) {}

  @Get()
  @FindAllKitchenQcDocs()
  findAll(@Query() query: PaginationDTO) {
    return this.kitchenQcService.findAll(
      (query.page - 1) * query.limit,
      query.limit,
    );
  }

  @Get('ticket/:ticketId/latest')
  @FindLatestKitchenQcDocs()
  findOneLatest(@Param('ticketId', ParseUUIDPipe) ticketId: string) {
    return this.kitchenQcService.findOneLatest(ticketId);
  }

  @Get('ticket/:ticketId')
  @FindKitchenQcByTicketDocs()
  findMany(@Param('ticketId', ParseUUIDPipe) ticketId: string) {
    return this.kitchenQcService.findMany(ticketId);
  }

  @Get('checker/:checkerId')
  @FindKitchenQcByCheckerDocs()
  findManyByChecker(
    @Param('checkerId', ParseUUIDPipe) checkerId: string,
    @Query() query: FindKitchenQcDTO,
  ) {
    return this.kitchenQcService.findManyByChecker(
      checkerId,
      query.activeOnly,
      (query.page - 1) * query.limit,
      query.limit,
    );
  }

  @Get(':id')
  @FindOneKitchenQcDocs()
  findOneUID(@Param('id', ParseUUIDPipe) attemptId: string) {
    return this.kitchenQcService.findOneUID(attemptId);
  }
}
