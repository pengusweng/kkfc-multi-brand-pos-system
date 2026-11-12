import {
  ForbiddenException,
  INestApplication,
  NotFoundException,
  ValidationPipe,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import {
  auditPipelineProviders,
  createAuditSpy,
} from '../../../shared/testing/audit.testing';
import { AuthService } from '../../auth/auth.service';
import { PinService } from '../../pin/pin.service';
import { UsersController } from '../users.controller';
import { UsersService } from '../users.service';

const actorId = '11111111-1111-4111-8111-111111111111';
const targetId = '22222222-2222-4222-8222-222222222222';
const newUserId = '33333333-3333-4333-8333-333333333333';

describe('Users audit logging', () => {
  let app: INestApplication;
  let url: string;
  let role: UserRole;
  const audit = createAuditSpy();
  const users = {
    createUser: jest.fn(),
    findAllUsers: jest.fn(),
    findOneUser: jest.fn(),
    updateUser: jest.fn(),
    deleteUser: jest.fn(),
  };
  const pins = { verifyPin: jest.fn() };
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
      controllers: [UsersController],
      providers: [
        { provide: UsersService, useValue: users },
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
    url = `${await app.getUrl()}/api/users`;
  });

  afterAll(async () => app.close());

  beforeEach(() => {
    role = UserRole.MANAGER;
    audit.create.mockClear().mockResolvedValue({});
    for (const mock of [...Object.values(users), pins.verifyPin]) {
      mock.mockReset();
    }
    pins.verifyPin.mockResolvedValue({ status: 'valid' });
  });

  function call(
    method: string,
    path = '',
    body?: unknown,
    pin: string | null = '1234',
  ) {
    return fetch(`${url}${path}`, {
      method,
      headers: {
        Authorization: 'Bearer token',
        'Content-Type': 'application/json',
        ...(pin ? { 'X-Action-Pin': pin } : {}),
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
  }

  const newUser = {
    username: 'new_cashier',
    first_name: 'New',
    last_name: 'Cashier',
    password: 'Password123!',
    role: UserRole.CASHIER_STAFF,
  };

  it('IT-USER-022: Given a manager with a valid PIN, When users are created, updated and deactivated, Then audit each with the affected user', async () => {
    users.createUser.mockResolvedValue({ user_id: newUserId });
    users.updateUser.mockResolvedValue({ user_id: targetId });
    users.deleteUser.mockResolvedValue({ user_id: targetId });

    const responses = [
      await call('POST', '', newUser),
      await call('PATCH', `/${targetId}`, { first_name: 'Renamed' }),
      await call('DELETE', `/${targetId}`),
    ];

    expect(responses.map((response) => response.status)).toEqual([
      201, 200, 200,
    ]);
    expect(audit.rows()).toEqual([
      expect.objectContaining({
        actor_id: actorId,
        action: 'USER_CREATED',
        entity_type: 'users',
        entity_id: newUserId,
        outcome: 'SUCCESS',
      }),
      expect.objectContaining({
        action: 'USER_UPDATED',
        entity_id: targetId,
        outcome: 'SUCCESS',
      }),
      expect.objectContaining({
        action: 'USER_DEACTIVATED',
        entity_id: targetId,
        outcome: 'SUCCESS',
      }),
    ]);
    expect(JSON.stringify(audit.rows())).not.toContain('Password123!');
  });

  it.each([
    [null, { status: 'valid' }, 'INVALID_PIN'],
    ['9999', { status: 'invalid' }, 'INVALID_PIN'],
    ['1234', { status: 'not-configured' }, 'PIN_NOT_CONFIGURED'],
    [
      '1234',
      { status: 'locked', until: new Date(Date.now() + 60_000) },
      'PIN_LOCKED',
    ],
  ])(
    'IT-USER-023: Given PIN %s with result %j, When a user is deactivated, Then audit a DENIED row with reason %s',
    async (pin, result, reason) => {
      pins.verifyPin.mockResolvedValue(result);

      const response = await call('DELETE', `/${targetId}`, undefined, pin);

      expect([403, 429]).toContain(response.status);
      expect(users.deleteUser).not.toHaveBeenCalled();
      expect(audit.rows()).toEqual([
        expect.objectContaining({
          actor_id: actorId,
          action: 'USER_DEACTIVATED',
          entity_id: targetId,
          outcome: 'DENIED',
          reason,
        }),
      ]);
    },
  );

  it('IT-USER-024: Given a manager, When users are listed or viewed by username, Then audit the sensitive reads with the viewed user', async () => {
    users.findAllUsers.mockResolvedValue({ data: [], meta: {} });
    users.findOneUser.mockResolvedValue({ user_id: targetId });

    const list = await call('GET', '?page=1&limit=10', undefined, null);
    const view = await call('GET', '/test_kitchen', undefined, null);

    expect([list.status, view.status]).toEqual([200, 200]);
    expect(audit.rows()).toEqual([
      expect.objectContaining({
        action: 'USERS_LISTED',
        entity_type: 'users',
        entity_id: null,
        outcome: 'SUCCESS',
      }),
      expect.objectContaining({
        action: 'USER_VIEWED',
        entity_id: targetId,
        outcome: 'SUCCESS',
      }),
    ]);
  });

  it('IT-USER-025: Given denied, forbidden-by-rule and missing targets, When users are managed, Then audit denials but not lookups that find nothing', async () => {
    users.updateUser.mockRejectedValue(
      new ForbiddenException({ code: 'CANNOT_MODIFY_PRIVILEGED_ACCOUNT' }),
    );
    users.findOneUser.mockRejectedValue(new NotFoundException());

    const protectedEdit = await call('PATCH', `/${targetId}`, {
      first_name: 'X',
    });
    const missing = await call('GET', `/${targetId}`, undefined, null);
    role = UserRole.KITCHEN_STAFF;
    const wrongRole = await call('GET', '?page=1&limit=10', undefined, null);

    expect([protectedEdit.status, missing.status, wrongRole.status]).toEqual([
      403, 404, 403,
    ]);
    expect(audit.rows()).toEqual([
      expect.objectContaining({
        action: 'USER_UPDATED',
        entity_id: targetId,
        outcome: 'DENIED',
        reason: 'CANNOT_MODIFY_PRIVILEGED_ACCOUNT',
      }),
      expect.objectContaining({
        action: 'USERS_LISTED',
        outcome: 'DENIED',
        reason: 'ACCESS_DENIED',
      }),
    ]);
  });
});
