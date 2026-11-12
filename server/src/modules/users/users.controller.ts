import { PinGuard } from '../pin/pin.guard';
import {
  UsersDocs,
  CreateUserDocs,
  UpdateUserDocs,
  FindAllUsersDocs,
  FindOneUserDocs,
  DeleteUserDocs,
} from './docs/users.docs';
import {
  Body,
  Controller,
  DefaultValuePipe,
  Delete,
  Get,
  Param,
  ParseBoolPipe,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { UsersService } from './users.service';
import { CreateUserDTO } from './dto/create-user.dto';
import { UpdateUserDTO } from './dto/update-user.dto';
import { FindUsersDTO } from './dto/find-users.dto';
import { Authenticated, type AuthenticatedRequest } from '../auth/auth.guard';
import { RolesGuard } from '../../shared/guards/roles.guard';
import { Roles } from '../../shared/decorators/roles.decorator';
import {
  Audit,
  type AuditResolver,
  fromParam,
  fromResult,
} from '../../shared/audit/audit.decorator';

// GET /users/:id accepts a username, so prefer the resolved user's ID.
const viewedUser: AuditResolver = (request, result) =>
  fromResult('user_id')(request, result) ?? fromParam('id')(request);

@Controller('users')
@UsersDocs()
@UseGuards(Authenticated, RolesGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post()
  @Audit({
    action: 'USER_CREATED',
    snapshot: 'create',
    entity: 'users',
    id: fromResult('user_id'),
  })
  @UseGuards(PinGuard)
  @CreateUserDocs()
  @Roles(UserRole.SUPERADMIN, UserRole.MANAGER)
  async create(
    @Body() dto: CreateUserDTO,
    @Req() request: AuthenticatedRequest,
  ) {
    return this.usersService.createUser(
      dto,
      request.session.user.role === UserRole.SUPERADMIN,
    );
  }

  @Get()
  @Audit({ action: 'USERS_LISTED', entity: 'users' })
  @FindAllUsersDocs()
  @Roles(UserRole.SUPERADMIN, UserRole.MANAGER)
  async findAll(@Query() query: FindUsersDTO) {
    return this.usersService.findAllUsers(query);
  }

  @Get(':id')
  @Audit({ action: 'USER_VIEWED', entity: 'users', id: viewedUser })
  @FindOneUserDocs()
  async findOne(
    @Param('id') usernameOrUserId: string,
    @Query('activeOnly', new DefaultValuePipe(true), ParseBoolPipe)
    activeOnly: boolean,
  ) {
    return this.usersService.findOneUser(usernameOrUserId, activeOnly);
  }

  @Patch(':id')
  @Audit({
    action: 'USER_UPDATED',
    snapshot: 'update',
    entity: 'users',
    id: fromParam('id'),
  })
  @UpdateUserDocs()
  @Roles(UserRole.SUPERADMIN, UserRole.MANAGER)
  @UseGuards(PinGuard)
  async update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateUserDTO,
    @Req() request: AuthenticatedRequest,
  ) {
    return this.usersService.updateUser(
      id,
      dto,
      request.session.user.role === UserRole.SUPERADMIN,
    );
  }

  @Delete(':id')
  @Audit({
    action: 'USER_DEACTIVATED',
    snapshot: 'update',
    entity: 'users',
    id: fromParam('id'),
  })
  @DeleteUserDocs()
  @Roles(UserRole.SUPERADMIN, UserRole.MANAGER)
  @UseGuards(PinGuard)
  async delete(
    @Param('id', ParseUUIDPipe) id: string,
    @Req() request: AuthenticatedRequest,
  ) {
    return this.usersService.deleteUser(
      id,
      request.session.user.role === UserRole.SUPERADMIN,
    );
  }
}
