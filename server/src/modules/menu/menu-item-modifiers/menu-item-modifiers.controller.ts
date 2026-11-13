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
import { MenuItemModifiersService } from './menu-item-modifiers.service';
import { Authenticated } from '../../auth/auth.guard';
import { RolesGuard } from '../../../shared/guards/roles.guard';
import { CreateMenuItemModifierDTO } from './dto/create-menu-item-modifier.dto';
import { UpdateMenuItemModifierDTO } from './dto/update-menu-item-modifier.dto';
import { FindAllMenuItemModifiersDTO } from './dto/find-all-menu-item-modifiers.dto';
import { FindMenuItemModifierDTO } from './dto/find-menu-item-modifier.dto';
import {
  MenuItemModifiersDocs,
  CreateMenuItemModifierDocs,
  FindAllMenuItemModifiersDocs,
  FindMenuItemModifiersForMenuItemDocs,
  FindOneMenuItemModifierDocs,
  UpdateMenuItemModifierDocs,
  ReactivateMenuItemModifierDocs,
  DeleteMenuItemModifierDocs,
} from './docs/menu-item-modifiers.docs';
import { Roles } from '../../../shared/decorators/roles.decorator';
import { UserRole } from '@prisma/client';

@UseMenuInterceptors(SafeMenuInterceptor)
@Controller('menu-item-modifiers')
@MenuItemModifiersDocs()
@UseGuards(Authenticated, RolesGuard)
export class MenuItemModifiersController {
  constructor(
    private readonly menuItemModifiersService: MenuItemModifiersService,
  ) {}

  @Post()
  @Audit({
    action: 'MENU_ITEM_MODIFIER_CREATED',
    snapshot: 'create',
    entity: 'menu_item_modifiers',
    id: fromResult('menu_item_modifier_id'),
  })
  @Roles(UserRole.SUPERADMIN, UserRole.RECIPE_MANAGER)
  @CreateMenuItemModifierDocs()
  async create(@Body() dto: CreateMenuItemModifierDTO) {
    return this.menuItemModifiersService.create(dto);
  }

  @Get()
  @FindAllMenuItemModifiersDocs()
  @Roles(UserRole.SUPERADMIN, UserRole.RECIPE_MANAGER)
  async findAll(@Query() query: FindAllMenuItemModifiersDTO) {
    return this.menuItemModifiersService.findAll(query);
  }

  @Get('menu-item/:menuItemId')
  @FindMenuItemModifiersForMenuItemDocs()
  @Roles(UserRole.SUPERADMIN, UserRole.RECIPE_MANAGER)
  async findManyForMenuItem(
    @Param('menuItemId', ParseUUIDPipe) menuItemId: string,
    @Query() query: FindMenuItemModifierDTO,
  ) {
    return this.menuItemModifiersService.findManyForMenuItem(
      menuItemId,
      query.activeOnly,
    );
  }

  @Get(':id')
  @FindOneMenuItemModifierDocs()
  async findOne(
    @Param('id', ParseUUIDPipe) menuItemModifierId: string,
    @Query() query: FindMenuItemModifierDTO,
  ) {
    return this.menuItemModifiersService.findOne(
      menuItemModifierId,
      query.activeOnly,
    );
  }

  @Patch(':id')
  @Audit({
    action: 'MENU_ITEM_MODIFIER_UPDATED',
    snapshot: 'update',
    entity: 'menu_item_modifiers',
    id: fromParam('id'),
  })
  @UpdateMenuItemModifierDocs()
  @Roles(UserRole.SUPERADMIN, UserRole.RECIPE_MANAGER)
  async update(
    @Param('id', ParseUUIDPipe) menuItemModifierId: string,
    @Body() dto: UpdateMenuItemModifierDTO,
  ) {
    return this.menuItemModifiersService.update(menuItemModifierId, dto);
  }

  @Patch('reactivate/:id')
  @Audit({
    action: 'MENU_ITEM_MODIFIER_REACTIVATED',
    snapshot: 'update',
    entity: 'menu_item_modifiers',
    id: fromParam('id'),
  })
  @ReactivateMenuItemModifierDocs()
  @Roles(UserRole.SUPERADMIN, UserRole.RECIPE_MANAGER)
  async reactivate(@Param('id', ParseUUIDPipe) menuItemModifierId: string) {
    return this.menuItemModifiersService.reactivate(menuItemModifierId);
  }

  @Delete(':id')
  @Audit({
    action: 'MENU_ITEM_MODIFIER_DEACTIVATED',
    snapshot: 'update',
    entity: 'menu_item_modifiers',
    id: fromParam('id'),
  })
  @DeleteMenuItemModifierDocs()
  @Roles(UserRole.SUPERADMIN, UserRole.RECIPE_MANAGER)
  async delete(@Param('id', ParseUUIDPipe) menuItemModifierId: string) {
    return this.menuItemModifiersService.delete(menuItemModifierId);
  }
}
