import {
  BadRequestException,
  ConflictException,
  ExecutionContext,
  ForbiddenException,
  InternalServerErrorException,
  Logger,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuditOutcome } from '@prisma/client';
import { firstValueFrom, of, throwError } from 'rxjs';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditContextGuard } from '../audit-context.guard';
import { AuditRecorder, classifyFailure } from '../audit-recorder.service';
import {
  Audit,
  AUDIT_KEY,
  AuditableRequest,
  AuditOptions,
  fromParam,
  fromResult,
  NoAudit,
} from '../audit.decorator';
import { AuditInterceptor } from '../audit.interceptor';

const actorId = '11111111-1111-4111-8111-111111111111';
const entityId = '22222222-2222-4222-8222-222222222222';
const audit: AuditOptions = {
  action: 'ORDER_CONFIRMED',
  entity: 'orders',
  id: fromParam('orderId'),
};

function request(overrides: Partial<AuditableRequest> = {}) {
  return {
    headers: {},
    params: { orderId: entityId },
    session: { user: { user_id: actorId } },
    audit,
    auditRequestId: 'req-1',
    ...overrides,
  } as unknown as AuditableRequest;
}

function httpContext(req: unknown, res: unknown = { setHeader: jest.fn() }) {
  return {
    getType: () => 'http',
    getHandler: () => handler,
    switchToHttp: () => ({ getRequest: () => req, getResponse: () => res }),
  } as unknown as ExecutionContext;
}

class Fixture {
  @Audit(audit)
  audited() {}

  plain() {}
}
const methodOf = (name: keyof Fixture) =>
  Object.getOwnPropertyDescriptor(Fixture.prototype, name)!.value as () => void;
const handler = methodOf('audited');

describe('Audit pipeline', () => {
  let create: jest.Mock;
  let recorder: AuditRecorder;
  let errorLog: jest.SpyInstance;
  const rowAt = (index: number) =>
    (create.mock.calls as Array<[{ data: Record<string, unknown> }]>)[index][0]
      .data;

  beforeEach(() => {
    create = jest.fn().mockResolvedValue({});
    recorder = new AuditRecorder({
      auditLog: { create },
    } as unknown as PrismaService);
    errorLog = jest.spyOn(Logger.prototype, 'error').mockImplementation();
  });

  afterEach(() => jest.restoreAllMocks());

  it('UT-AUDIT-005: Given an audited request, When it succeeds, Then record a SUCCESS row with actor, entity and request ID', async () => {
    await recorder.recordSuccess(request(), { order_id: entityId });

    expect(create).toHaveBeenCalledWith({
      data: {
        actor_id: actorId,
        action: 'ORDER_CONFIRMED',
        entity_type: 'orders',
        entity_id: entityId,
        outcome: AuditOutcome.SUCCESS,
        request_id: 'req-1',
      },
    });
  });

  it.each([
    [
      new UnauthorizedException({ code: 'INVALID_SESSION' }),
      'DENIED',
      'INVALID_SESSION',
    ],
    [
      new ForbiddenException({ code: 'ACCESS_DENIED' }),
      'DENIED',
      'ACCESS_DENIED',
    ],
    [
      new ConflictException({ code: 'KITCHEN_TICKET_INVALID_STATUS' }),
      'FAILED',
      'KITCHEN_TICKET_INVALID_STATUS',
    ],
    [
      new ConflictException('Only draft orders can be confirmed.'),
      'FAILED',
      'HTTP_409',
    ],
    [
      new ConflictException({ code: 'not a code; DROP TABLE' }),
      'FAILED',
      'HTTP_409',
    ],
    [new InternalServerErrorException(), 'FAILED', 'HTTP_500'],
    [new Error('boom'), 'FAILED', 'INTERNAL_ERROR'],
  ])(
    'UT-AUDIT-006: Given %p, When the failure is classified, Then record %s with reason %s',
    (exception, outcome, reason) => {
      expect(classifyFailure(exception)).toEqual({ outcome, reason });
    },
  );

  it.each([
    new BadRequestException(['field is required']),
    new NotFoundException({ code: 'ORDER_NOT_FOUND' }),
  ])(
    'UT-AUDIT-007: Given a %p, When the failure is classified, Then it is not audited',
    async (exception) => {
      expect(classifyFailure(exception)).toBeNull();
      await recorder.recordFailure(request(), exception);
      expect(create).not.toHaveBeenCalled();
    },
  );

  it('UT-AUDIT-008: Given a denied request, When the failure is recorded, Then store the code as the reason without the message', async () => {
    await recorder.recordFailure(
      request({ session: undefined }),
      new UnauthorizedException({
        code: 'SESSION_TOKEN_REQUIRED',
        message: 'A bearer session token is required.',
      }),
    );

    expect(create).toHaveBeenCalledTimes(1);
    expect(rowAt(0)).toMatchObject({
      actor_id: null,
      outcome: AuditOutcome.DENIED,
      reason: 'SESSION_TOKEN_REQUIRED',
    });
    expect(JSON.stringify(create.mock.calls)).not.toContain('bearer');
  });

  it('UT-AUDIT-009: Given non-UUID IDs or a custom resolver, When a row is recorded, Then store null IDs or the resolved values', async () => {
    await recorder.recordSuccess(
      request({ params: { orderId: 'not-a-uuid' }, session: undefined }),
      undefined,
    );
    await recorder.recordSuccess(
      request({
        session: undefined,
        audit: {
          action: 'AUTH_LOGIN',
          entity: 'users',
          id: fromResult('user_id'),
          actor: fromResult('user_id'),
        },
      }),
      { user_id: actorId },
    );

    expect(rowAt(0)).toMatchObject({
      actor_id: null,
      entity_id: null,
    });
    expect(rowAt(1)).toMatchObject({
      actor_id: actorId,
      entity_id: actorId,
    });
  });

  it('UT-AUDIT-010: Given an audit storage outage, When a row is recorded, Then resolve without throwing and log a constant message', async () => {
    create.mockRejectedValue(new Error('connection refused to db:5432'));

    await expect(
      recorder.recordSuccess(request(), undefined),
    ).resolves.toBeUndefined();
    expect(errorLog).toHaveBeenCalledWith(
      'Failed to persist SUCCESS audit event.',
    );
    expect(JSON.stringify(errorLog.mock.calls)).not.toContain('5432');
  });

  it('UT-AUDIT-011: Given a route request, When the context guard runs, Then attach audit metadata and a request ID without blocking', () => {
    const guard = new AuditContextGuard(new Reflector());
    const res = { setHeader: jest.fn() };
    const generated = request({ audit: undefined, auditRequestId: undefined });
    const echoed = request({
      audit: undefined,
      auditRequestId: undefined,
      headers: { 'x-request-id': 'client-abc_123' },
    });
    const unsafe = request({
      audit: undefined,
      auditRequestId: undefined,
      headers: { 'x-request-id': 'bad id\r\nSet-Cookie: x' },
    });

    expect(guard.canActivate(httpContext(generated, res))).toBe(true);
    expect(guard.canActivate(httpContext(echoed, res))).toBe(true);
    expect(guard.canActivate(httpContext(unsafe, res))).toBe(true);

    expect(generated.audit).toEqual(audit);
    expect(generated.auditRequestId).toMatch(/^[0-9a-f-]{36}$/);
    expect(echoed.auditRequestId).toBe('client-abc_123');
    expect(unsafe.auditRequestId).toMatch(/^[0-9a-f-]{36}$/);
    expect(res.setHeader).toHaveBeenCalledWith(
      'x-request-id',
      'client-abc_123',
    );
  });

  it('UT-AUDIT-012: Given a handler result, When the interceptor runs, Then record success only for audited routes and pass the result through', async () => {
    const recordSuccess = jest
      .spyOn(recorder, 'recordSuccess')
      .mockResolvedValue();
    const interceptor = new AuditInterceptor(recorder);
    const result = { order_id: entityId };

    const audited = request();
    await expect(
      firstValueFrom(
        interceptor.intercept(httpContext(audited), {
          handle: () => of(result),
        }),
      ),
    ).resolves.toBe(result);
    expect(recordSuccess).toHaveBeenCalledWith(audited, result);

    recordSuccess.mockClear();
    await firstValueFrom(
      interceptor.intercept(httpContext(request({ audit: undefined })), {
        handle: () => of(result),
      }),
    );
    expect(recordSuccess).not.toHaveBeenCalled();

    await expect(
      firstValueFrom(
        interceptor.intercept(httpContext(request()), {
          handle: () => throwError(() => new ConflictException()),
        }),
      ),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(recordSuccess).not.toHaveBeenCalled();
  });

  it.each([
    [() => Audit({ action: 'order confirmed', entity: 'orders' })],
    [() => Audit({ action: 'ORDER_CONFIRMED', entity: 'Orders' })],
    [() => NoAudit('  ')],
  ])(
    'UT-AUDIT-013: Given invalid decorator options %#, When the decorator is created, Then throw at startup',
    (create) => {
      expect(create).toThrow();
    },
  );

  it('UT-AUDIT-014: Given a decorated method, When metadata is read, Then expose the audit options', () => {
    expect(new Reflector().get(AUDIT_KEY, handler)).toEqual(audit);
    expect(new Reflector().get(AUDIT_KEY, methodOf('plain'))).toBeUndefined();
  });
});
