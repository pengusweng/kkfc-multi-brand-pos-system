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
import { MenuChannelsService } from './menu-channels.service';
import { CreateMenuChannelDTO } from './dto/create-menu-channel.dto';
import { FindAllMenuChannelsDTO } from './dto/find-all-menu-channels.dto';
import { FindMenuChannelDTO } from './dto/find-menu-channel.dto';
import { FindMenuItemChannelsDTO } from './dto/find-menu-item-channels.dto';
import { UpdateMenuItemChannelDTO } from './dto/update-menu-item-channel.dto';
import { Authenticated } from '../../auth/auth.guard';
import { RolesGuard } from '../../../shared/guards/roles.guard';
import { Roles } from '../../../shared/decorators/roles.decorator';
import { UserRole } from '@prisma/client';
import {
  MenuChannelsDocs,
  CreateMenuChannelDocs,
  FindAllMenuChannelsDocs,
  FindMenuChannelsByMenuItemDocs,
  FindOneMenuChannelDocs,
  UpdateMenuChannelDocs,
  ReactivateMenuChannelDocs,
  DeleteMenuChannelDocs,
} from './docs/menu-channels.docs';

@UseMenuInterceptors(SafeMenuInterceptor)
@Controller('menu-channels')
@MenuChannelsDocs()
@UseGuards(Authenticated, RolesGuard)
export class MenuChannelsController {
  constructor(private readonly menuChannelsService: MenuChannelsService) {}

  @Post()
  @Audit({
    action: 'MENU_ITEM_CHANNEL_CREATED',
    snapshot: 'create',
    entity: 'menu_item_channels',
    id: fromResult('menu_item_channel_id'),
  })
  @CreateMenuChannelDocs()
  @Roles(UserRole.SUPERADMIN, UserRole.MANAGER)
  async create(@Body() dto: CreateMenuChannelDTO) {
    return this.menuChannelsService.create(dto);
  }

  @Get()
  @FindAllMenuChannelsDocs()
  @Roles(UserRole.SUPERADMIN)
  async findAll(@Query() query: FindAllMenuChannelsDTO) {
    return this.menuChannelsService.findAll(query);
  }

  @Get('menu-item/:menuItemId')
  @FindMenuChannelsByMenuItemDocs()
  async findManyByMenuItem(
    @Param('menuItemId', ParseUUIDPipe) menuItemId: string,
    @Query() query: FindMenuItemChannelsDTO,
  ) {
    return this.menuChannelsService.findManyByMenuItem(menuItemId, query);
  }

  @Get(':id')
  @FindOneMenuChannelDocs()
  async findOne(
    @Param('id', ParseUUIDPipe) menuItemChannelId: string,
    @Query() query: FindMenuChannelDTO,
  ) {
    return this.menuChannelsService.findOne(
      menuItemChannelId,
      query.activeOnly,
    );
  }

  @Patch(':id')
  @Audit({
    action: 'MENU_ITEM_CHANNEL_UPDATED',
    snapshot: 'update',
    entity: 'menu_item_channels',
    id: fromParam('id'),
  })
  @UpdateMenuChannelDocs()
  @Roles(UserRole.SUPERADMIN, UserRole.MANAGER)
  async update(
    @Param('id', ParseUUIDPipe) menuItemChannelId: string,
    @Body() dto: UpdateMenuItemChannelDTO,
  ) {
    return this.menuChannelsService.update(menuItemChannelId, dto);
  }

  @Patch('reactivate/:id')
  @Audit({
    action: 'MENU_ITEM_CHANNEL_REACTIVATED',
    snapshot: 'update',
    entity: 'menu_item_channels',
    id: fromParam('id'),
  })
  @ReactivateMenuChannelDocs()
  @Roles(UserRole.SUPERADMIN, UserRole.MANAGER)
  async reactivate(@Param('id', ParseUUIDPipe) menuItemChannelId: string) {
    return this.menuChannelsService.reactivate(menuItemChannelId);
  }

  @Delete(':id')
  @Audit({
    action: 'MENU_ITEM_CHANNEL_DEACTIVATED',
    snapshot: 'update',
    entity: 'menu_item_channels',
    id: fromParam('id'),
  })
  @DeleteMenuChannelDocs()
  @Roles(UserRole.SUPERADMIN, UserRole.MANAGER)
  async delete(@Param('id', ParseUUIDPipe) menuItemChannelId: string) {
    return this.menuChannelsService.delete(menuItemChannelId);
  }
}
