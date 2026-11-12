import {
  INestApplication,
  NotFoundException,
  UnauthorizedException,
  ValidationPipe,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import {
  auditPipelineProviders,
  createAuditSpy,
} from '../../../shared/testing/audit.testing';
import { AuthController } from '../auth.controller';
import { AuthService } from '../auth.service';

const userId = '11111111-1111-4111-8111-111111111111';
const sessionId = '22222222-2222-4222-8222-222222222222';

describe('Auth audit logging', () => {
  let app: INestApplication;
  let url: string;
  const audit = createAuditSpy();
  const auth = {
    login: jest.fn(),
    validateSession: jest.fn(),
    getUserProfile: jest.fn(),
    deleteSession: jest.fn(),
    deleteUserSessions: jest.fn(),
  };

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [AuthController],
      providers: [
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
    url = `${await app.getUrl()}/api/auth`;
  });

  afterAll(async () => app.close());

  beforeEach(() => {
    jest.resetAllMocks();
    audit.create.mockResolvedValue({});
    auth.validateSession.mockImplementation((token: string) =>
      token === 'valid'
        ? Promise.resolve({
            session_id: sessionId,
            user_id: userId,
            user: { user_id: userId, role: UserRole.KITCHEN_STAFF },
          })
        : Promise.reject(new NotFoundException()),
    );
  });

  function post(path: string, body?: unknown, token?: string) {
    return fetch(`${url}${path}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
  }

  it('IT-AUTH-015: Given valid credentials, When a user logs in, Then audit AUTH_LOGIN for that user without the session token', async () => {
    auth.login.mockResolvedValue({
      token: 'secret-session-token',
      expires_at: new Date(),
      user: { user_id: userId },
    });

    const response = await post('/login', {
      username: 'test_kitchen',
      password: 'Password123!',
    });

    expect(response.status).toBe(200);
    expect(audit.rows()).toEqual([
      {
        actor_id: userId,
        action: 'AUTH_LOGIN',
        entity_type: 'users',
        entity_id: userId,
        outcome: 'SUCCESS',
        request_id: response.headers.get('x-request-id'),
      },
    ]);
    const stored = JSON.stringify(audit.rows());
    expect(stored).not.toContain('secret-session-token');
    expect(stored).not.toContain('Password123!');
    expect(stored).not.toContain('test_kitchen');
  });

  it('IT-AUTH-016: Given wrong credentials or a malformed body, When a user logs in, Then audit only the rejected credentials as DENIED', async () => {
    auth.login.mockRejectedValue(
      new UnauthorizedException({
        code: 'INVALID_CREDENTIALS',
        message: 'Invalid username or password.',
      }),
    );

    const rejected = await post('/login', {
      username: 'test_kitchen',
      password: 'wrong',
    });
    const malformed = await post('/login', { username: 'test_kitchen' });

    expect(rejected.status).toBe(401);
    expect(malformed.status).toBe(400);
    expect(audit.rows()).toEqual([
      expect.objectContaining({
        actor_id: null,
        action: 'AUTH_LOGIN',
        entity_id: null,
        outcome: 'DENIED',
        reason: 'INVALID_CREDENTIALS',
      }),
    ]);
  });

  it('IT-AUTH-017: Given a session, When the user logs out or logs out everywhere, Then audit the session or user; reads and invalid tokens are handled', async () => {
    const logout = await post('/logout', undefined, 'valid');
    const logoutAll = await post('/logout-all', undefined, 'valid');
    const expired = await post('/logout', undefined, 'expired');
    const me = await fetch(`${url}/me`, {
      headers: { Authorization: 'Bearer valid' },
    });

    expect([
      logout.status,
      logoutAll.status,
      expired.status,
      me.status,
    ]).toEqual([204, 204, 401, 200]);
    expect(audit.rows()).toEqual([
      expect.objectContaining({
        actor_id: userId,
        action: 'AUTH_LOGOUT',
        entity_type: 'user_sessions',
        entity_id: sessionId,
        outcome: 'SUCCESS',
      }),
      expect.objectContaining({
        actor_id: userId,
        action: 'AUTH_LOGOUT_ALL',
        entity_type: 'users',
        entity_id: userId,
        outcome: 'SUCCESS',
      }),
      expect.objectContaining({
        actor_id: null,
        action: 'AUTH_LOGOUT',
        entity_id: null,
        outcome: 'DENIED',
        reason: 'INVALID_SESSION',
      }),
    ]);
  });
});
