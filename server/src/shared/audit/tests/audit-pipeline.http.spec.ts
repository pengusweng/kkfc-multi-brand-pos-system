import {
  CanActivate,
  ConflictException,
  Controller,
  ExecutionContext,
  Get,
  INestApplication,
  Injectable,
  Param,
  ParseUUIDPipe,
  Post,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { APP_FILTER, APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { Test } from '@nestjs/testing';
import { Prisma, UserRole } from '@prisma/client';
import { Roles } from '../../decorators/roles.decorator';
import { AllExceptionsFilter } from '../../filters/all-exceptions.filter';
import { PrismaExceptionFilter } from '../../filters/prisma-exception.filter';
import { RolesGuard } from '../../guards/roles.guard';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditContextGuard } from '../audit-context.guard';
import { AuditRecorder } from '../audit-recorder.service';
import { Audit, fromParam } from '../audit.decorator';
import { AuditInterceptor } from '../audit.interceptor';

const actorId = '11111111-1111-4111-8111-111111111111';
const entityId = '22222222-2222-4222-8222-222222222222';

/** Stand-in for Authenticated: the x-role header plays the session. */
@Injectable()
class FakeAuthGuard implements CanActivate {
  canActivate(context: ExecutionContext) {
    const request = context.switchToHttp().getRequest<{
      headers: Record<string, string | undefined>;
      session?: unknown;
    }>();
    const role = request.headers['x-role'];
    if (!role) {
      throw new UnauthorizedException({
        code: 'SESSION_TOKEN_REQUIRED',
        message: 'A bearer session token is required.',
      });
    }
    request.session = { user_id: actorId, user: { user_id: actorId, role } };
    return true;
  }
}

@Controller('things')
@UseGuards(FakeAuthGuard, RolesGuard)
@Roles(UserRole.SUPERVISOR)
class ThingsController {
  @Post(':id')
  @Audit({ action: 'THING_UPDATED', entity: 'things', id: fromParam('id') })
  update(@Param('id', ParseUUIDPipe) id: string) {
    return { thing_id: id };
  }

  @Post(':id/conflict')
  @Audit({ action: 'THING_LOCKED', entity: 'things', id: fromParam('id') })
  conflict() {
    throw new ConflictException({ code: 'THING_ALREADY_LOCKED' });
  }

  @Post(':id/duplicate')
  @Audit({ action: 'THING_COPIED', entity: 'things', id: fromParam('id') })
  duplicate() {
    throw new Prisma.PrismaClientKnownRequestError('Unique constraint', {
      code: 'P2002',
      clientVersion: 'test',
    });
  }

  @Get()
  list() {
    return [];
  }
}

describe('Audit pipeline HTTP', () => {
  let app: INestApplication;
  let url: string;
  const create = jest.fn();

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [ThingsController],
      providers: [
        AuditRecorder,
        { provide: PrismaService, useValue: { auditLog: { create } } },
        { provide: APP_FILTER, useClass: AllExceptionsFilter },
        { provide: APP_FILTER, useClass: PrismaExceptionFilter },
        { provide: APP_GUARD, useClass: AuditContextGuard },
        { provide: APP_INTERCEPTOR, useClass: AuditInterceptor },
      ],
    }).compile();
    app = module.createNestApplication();
    app.useLogger(false);
    await app.listen(0);
    url = await app.getUrl();
  });

  afterAll(async () => app.close());

  beforeEach(() => {
    create.mockReset().mockResolvedValue({});
  });

  function call(path: string, role: string | null = UserRole.SUPERVISOR) {
    return fetch(`${url}/things${path}`, {
      method: path ? 'POST' : 'GET',
      headers: role ? { 'x-role': role } : {},
    });
  }

  const rows = () =>
    create.mock.calls.map(
      ([{ data }]: [{ data: Record<string, unknown> }]) => data,
    );

  it('IT-AUDIT-008: Given an audited action, When it succeeds, Then write one SUCCESS row before responding', async () => {
    const response = await call(`/${entityId}`);

    expect(response.status).toBe(201);
    expect(rows()).toEqual([
      {
        actor_id: actorId,
        action: 'THING_UPDATED',
        entity_type: 'things',
        entity_id: entityId,
        outcome: 'SUCCESS',
        request_id: response.headers.get('x-request-id'),
      },
    ]);
  });

  it.each([
    [null, 401, 'SESSION_TOKEN_REQUIRED', null],
    [UserRole.KITCHEN_STAFF, 403, 'ACCESS_DENIED', actorId],
  ])(
    'IT-AUDIT-009: Given role %s, When a guard rejects the action, Then write a DENIED row with reason and actor',
    async (role, status, reason, actor) => {
      const response = await call(`/${entityId}`, role);

      expect(response.status).toBe(status);
      expect(rows()).toEqual([
        expect.objectContaining({
          action: 'THING_UPDATED',
          entity_id: entityId,
          outcome: 'DENIED',
          reason,
          actor_id: actor,
        }),
      ]);
    },
  );

  it.each([
    ['/conflict', 'THING_LOCKED', 'THING_ALREADY_LOCKED'],
    ['/duplicate', 'THING_COPIED', 'DUPLICATE_RESOURCE'],
  ])(
    'IT-AUDIT-010: Given %s, When the action fails with a conflict, Then write a FAILED row with the error code',
    async (suffix, action, reason) => {
      const response = await call(`/${entityId}${suffix}`);

      expect(response.status).toBe(409);
      expect(rows()).toEqual([
        expect.objectContaining({ action, outcome: 'FAILED', reason }),
      ]);
    },
  );

  it('IT-AUDIT-011: Given a validation error or an unaudited route, When the request completes, Then write no audit row but still return a request ID', async () => {
    const invalid = await call('/not-a-uuid');
    const unaudited = await call('');

    expect(invalid.status).toBe(400);
    expect(unaudited.status).toBe(200);
    expect(unaudited.headers.get('x-request-id')).toMatch(/^[0-9a-f-]{36}$/);
    expect(create).not.toHaveBeenCalled();
  });

  it('IT-AUDIT-012: Given an audit storage outage, When an audited action succeeds, Then the response is unchanged', async () => {
    create.mockRejectedValue(new Error('db down'));

    const response = await call(`/${entityId}`);

    expect(response.status).toBe(201);
    expect(await response.json()).toEqual({ thing_id: entityId });
  });
});
