import {
  ConflictException,
  INestApplication,
  UnauthorizedException,
  ValidationPipe,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import {
  auditPipelineProviders,
  createAuditSpy,
} from '../../../shared/testing/audit.testing';
import { AuthService } from '../../auth/auth.service';
import { PinController } from '../pin.controller';
import { PinService } from '../pin.service';

const actorId = '11111111-1111-4111-8111-111111111111';

describe('PIN audit logging', () => {
  let app: INestApplication;
  let url: string;
  let role: UserRole;
  const audit = createAuditSpy();
  const pins = { create: jest.fn(), findOne: jest.fn(), updatePin: jest.fn() };
  const auth = {
    validateSession: jest.fn(() =>
      Promise.resolve({
        session_id: 'session',
        user_id: actorId,
        user: { user_id: actorId, role },
      }),
    ),
  };

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [PinController],
      providers: [
        { provide: PinService, useValue: pins },
        { provide: AuthService, useValue: auth },
        ...auditPipelineProviders(audit),
      ],
    }).compile();
    app = module.createNestApplication();
    app.useLogger(false);
    app.setGlobalPrefix('api');
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    await app.listen(0);
    url = `${await app.getUrl()}/api/pin`;
  });

  afterAll(async () => app.close());

  beforeEach(() => {
    role = UserRole.SUPERVISOR;
    audit.create.mockClear().mockResolvedValue({});
    for (const mock of Object.values(pins)) mock.mockReset();
  });

  function call(method: string, body?: unknown) {
    return fetch(url, {
      method,
      headers: {
        Authorization: 'Bearer token',
        'Content-Type': 'application/json',
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
  }

  it('IT-PIN-024: Given a supervisor, When they set and change their PIN, Then audit both against their own credential without secrets', async () => {
    pins.create.mockResolvedValue({ user_id: actorId });
    pins.updatePin.mockResolvedValue({ user_id: actorId });

    const created = await call('POST', { pin: '4821' });
    const updated = await call('PATCH', {
      pin: '7395',
      password: 'Password123!',
    });

    expect([created.status, updated.status]).toEqual([201, 200]);
    expect(audit.rows()).toEqual([
      expect.objectContaining({
        actor_id: actorId,
        action: 'PIN_CREATED',
        entity_type: 'user_pin_credentials',
        entity_id: actorId,
        outcome: 'SUCCESS',
      }),
      expect.objectContaining({
        actor_id: actorId,
        action: 'PIN_UPDATED',
        entity_id: actorId,
        outcome: 'SUCCESS',
      }),
    ]);
    const stored = JSON.stringify(audit.rows());
    for (const secret of ['4821', '7395', 'Password123!']) {
      expect(stored).not.toContain(secret);
    }
  });

  it('IT-PIN-025: Given an existing PIN or a wrong password, When the PIN is set or changed, Then audit FAILED and DENIED with the error codes', async () => {
    pins.create.mockRejectedValue(
      new ConflictException({ code: 'EXISTING_PIN_FOUND' }),
    );
    pins.updatePin.mockRejectedValue(
      new UnauthorizedException({ code: 'INVALID_CREDENTIALS' }),
    );

    const created = await call('POST', { pin: '4821' });
    const updated = await call('PATCH', { pin: '7395', password: 'wrong' });

    expect([created.status, updated.status]).toEqual([409, 401]);
    expect(audit.rows()).toEqual([
      expect.objectContaining({
        action: 'PIN_CREATED',
        outcome: 'FAILED',
        reason: 'EXISTING_PIN_FOUND',
      }),
      expect.objectContaining({
        action: 'PIN_UPDATED',
        outcome: 'DENIED',
        reason: 'INVALID_CREDENTIALS',
      }),
    ]);
  });

  it('IT-PIN-026: Given a role without PINs, a malformed PIN and a status read, When the PIN endpoints are called, Then only the role denial is audited', async () => {
    pins.findOne.mockResolvedValue({ configured: true });

    const status = await call('GET');
    const malformed = await call('POST', { pin: '12' });
    role = UserRole.KITCHEN_STAFF;
    const wrongRole = await call('POST', { pin: '4821' });

    expect([status.status, malformed.status, wrongRole.status]).toEqual([
      200, 400, 403,
    ]);
    expect(pins.create).not.toHaveBeenCalled();
    expect(audit.rows()).toEqual([
      expect.objectContaining({
        actor_id: actorId,
        action: 'PIN_CREATED',
        outcome: 'DENIED',
        reason: 'ACCESS_DENIED',
      }),
    ]);
  });
});
