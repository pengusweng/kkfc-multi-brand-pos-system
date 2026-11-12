import {
  AuthDocs,
  LoginDocs,
  MeDocs,
  LogoutDocs,
  LogoutAllDocs,
} from './docs/auth.docs';
import {
  Body,
  Controller,
  Get,
  Header,
  HttpCode,
  HttpStatus,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { AuthenticatedRequest } from './auth.guard';
import { Authenticated } from './auth.guard';
import { AuthService } from './auth.service';
import { LoginDTO } from './dto/login.dto';
import { Audit, type AuditResolver } from '../../shared/audit/audit.decorator';

// Login has no session yet: the actor is the user the response logged in. Only
// user_id is read; the session token never reaches the audit row.
const loggedInUser: AuditResolver = (_request, result) =>
  (result as { user?: { user_id?: unknown } } | undefined)?.user?.user_id;
const currentSession: AuditResolver = (request) =>
  (request.session as { session_id?: unknown } | undefined)?.session_id;
const currentUser: AuditResolver = (request) => request.session?.user_id;

@Controller('auth')
@AuthDocs()
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('login')
  @Audit({
    action: 'AUTH_LOGIN',
    entity: 'users',
    id: loggedInUser,
    actor: loggedInUser,
  })
  @Header('Cache-Control', 'no-store')
  @HttpCode(HttpStatus.OK)
  @LoginDocs()
  async login(@Body() dto: LoginDTO) {
    return this.authService.login(dto);
  }

  @Get('me')
  @Header('Cache-Control', 'no-store')
  @UseGuards(Authenticated)
  @MeDocs()
  me(@Req() request: AuthenticatedRequest) {
    return this.authService.getUserProfile(request.session.user);
  }

  @Post('logout')
  @Audit({ action: 'AUTH_LOGOUT', entity: 'user_sessions', id: currentSession })
  @UseGuards(Authenticated)
  @HttpCode(HttpStatus.NO_CONTENT)
  @LogoutDocs()
  async logout(@Req() request: AuthenticatedRequest) {
    await this.authService.deleteSession(request.session.session_id);
  }

  @Post('logout-all')
  @Audit({ action: 'AUTH_LOGOUT_ALL', entity: 'users', id: currentUser })
  @UseGuards(Authenticated)
  @HttpCode(HttpStatus.NO_CONTENT)
  @LogoutAllDocs()
  async logoutAll(@Req() request: AuthenticatedRequest) {
    await this.authService.deleteUserSessions(request.session.user_id);
  }
}
