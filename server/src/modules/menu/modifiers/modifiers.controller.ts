import {
  Audit,
  fromParam,
  fromResult,
} from '../../../shared/audit/audit.decorator';
import { UseInterceptors as UseMenuInterceptors } from '@nestjs/common';
import { SafeMenuInterceptor } from '../safe-menu.interceptor';
import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ModifiersDocs,
  CreateModifierDocs,
  FindAllModifiersDocs,
  FindOneModifierDocs,
  UpdateModifierDocs,
  ReactivateModifierDocs,
  DeleteModifierDocs,
} from './docs/modifiers.docs';
import { ModifiersService } from './modifiers.service';
import { CreateModifierDTO } from './dto/create-modifier.dto';
import { FindAllModifiersDTO } from './dto/find-all-modifiers.dto';
import { FindModifierDTO } from './dto/find-modifier.dto';
import { UpdateModifierDTO } from './dto/update-modifier.dto';
import { Authenticated } from '../../auth/auth.guard';
import { RolesGuard } from '../../../shared/guards/roles.guard';
import { Roles } from '../../../shared/decorators/roles.decorator';
import { UserRole } from '@prisma/client';

@UseMenuInterceptors(SafeMenuInterceptor)
@Controller('modifiers')
@ModifiersDocs()
@UseGuards(Authenticated, RolesGuard)
@Roles(UserRole.SUPERADMIN, UserRole.RECIPE_MANAGER)
export class ModifiersController {
  constructor(private readonly modifiersService: ModifiersService) {}

  @Post()
  @Audit({
    action: 'MODIFIER_CREATED',
    snapshot: 'create',
    entity: 'modifiers',
    id: fromResult('modifier_id'),
  })
  @CreateModifierDocs()
  async create(@Body() dto: CreateModifierDTO) {
    return this.modifiersService.create(dto);
  }

  @Get()
  @FindAllModifiersDocs()
  async findAll(@Query() query: FindAllModifiersDTO) {
    return this.modifiersService.findAll(query);
  }

  @Get(':id')
  @FindOneModifierDocs()
  async findOne(
    @Param('id') codeOrModifierId: string,
    @Query() query: FindModifierDTO,
  ) {
    return this.modifiersService.findOne(codeOrModifierId, query.activeOnly);
  }

  @Patch(':id')
  @Audit({
    action: 'MODIFIER_UPDATED',
    snapshot: 'update',
    entity: 'modifiers',
    id: fromParam('id'),
  })
  @UpdateModifierDocs()
  async update(
    @Param('id', ParseUUIDPipe) modifierId: string,
    @Body() dto: UpdateModifierDTO,
  ) {
    return this.modifiersService.update(modifierId, dto);
  }

  @Patch('reactivate/:id')
  @Audit({
    action: 'MODIFIER_REACTIVATED',
    snapshot: 'update',
    entity: 'modifiers',
    id: fromParam('id'),
  })
  @ReactivateModifierDocs()
  async reactivate(@Param('id', ParseUUIDPipe) modifierId: string) {
    return this.modifiersService.reactivate(modifierId);
  }

  @Delete(':id')
  @Audit({
    action: 'MODIFIER_DEACTIVATED',
    snapshot: 'update',
    entity: 'modifiers',
    id: fromParam('id'),
  })
  @DeleteModifierDocs()
  async delete(@Param('id', ParseUUIDPipe) modifierId: string) {
    return this.modifiersService.delete(modifierId);
  }
}
