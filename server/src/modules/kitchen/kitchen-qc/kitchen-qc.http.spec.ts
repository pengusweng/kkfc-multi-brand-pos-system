import {
  INestApplication,
  NotFoundException,
  ValidationPipe,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { KitchenTicketQcStatus, UserRole } from '@prisma/client';
import { AuthService } from '../../auth/auth.service';
import { KitchenQcController } from './kitchen-qc.controller';
import { KitchenQcService } from './kitchen-qc.service';

describe('Kitchen QC retrieval HTTP endpoints', () => {
  const attemptId = '00000000-0000-4000-8000-000000000001';
  const ticketId = '00000000-0000-4000-8000-000000000002';
  const checkerId = '00000000-0000-4000-8000-000000000003';
  const attempt = {
    qc_attempt_id: attemptId,
    kitchen_ticket_id: ticketId,
    attempt_number: 1,
    checker_id: checkerId,
    status: KitchenTicketQcStatus.IN_PROGRESS,
    started_at: '2026-11-01T04:00:00.000Z',
    completed_at: null,
  };
  const allowedRoles: UserRole[] = [
    UserRole.SUPERADMIN,
    UserRole.MANAGER,
    UserRole.SUPERVISOR,
    UserRole.KITCHEN_HEAD,
    UserRole.KITCHEN_STAFF,
  ];
  const auth = { validateSession: jest.fn() };
  const service = {
    findAll: jest.fn(),
    findOneUID: jest.fn(),
    findOneLatest: jest.fn(),
    findMany: jest.fn(),
    findManyByChecker: jest.fn(),
  };
  const routes = [
    {
      path: '',
      handler: 'findAll',
      args: [0, 10],
      result: { qcAttempts: [attempt], total: 1 },
    },
    {
      path: `/ticket/${ticketId}/latest`,
      handler: 'findOneLatest',
      args: [ticketId],
      result: attempt,
    },
    {
      path: `/ticket/${ticketId}`,
      handler: 'findMany',
      args: [ticketId],
      result: [attempt],
    },
    {
      path: `/checker/${checkerId}`,
      handler: 'findManyByChecker',
      args: [checkerId, true, 0, 10],
      result: { qcAttempts: [attempt], total: 1 },
    },
    {
      path: `/${attemptId}`,
      handler: 'findOneUID',
      args: [attemptId],
      result: attempt,
    },
  ] as const;
  let app: INestApplication;
  let url: string;

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [KitchenQcController],
      providers: [
        { provide: KitchenQcService, useValue: service },
        { provide: AuthService, useValue: auth },
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
    await app.listen(0, '127.0.0.1');
    url = `${await app.getUrl()}/api/kitchen-qc`;
  });

  beforeEach(() => {
    jest.resetAllMocks();
    auth.validateSession.mockImplementation((role: UserRole) =>
      Promise.resolve({ user: { user_id: checkerId, role } }),
    );
    for (const route of routes) {
      service[route.handler].mockResolvedValue(route.result);
    }
  });

  afterAll(async () => app?.close());

  function request(
    path = '',
    authorization: string | null = `Bearer ${UserRole.KITCHEN_HEAD}`,
  ) {
    return fetch(`${url}${path}`, {
      headers: authorization === null ? {} : { Authorization: authorization },
    });
  }

  describe.each(routes)('GET $path', (route) => {
    it.each(allowedRoles)(
      'IT-KQC-001: allows %s and forwards validated arguments',
      async (role) => {
        const response = await request(route.path, `Bearer ${role}`);

        expect(response.status).toBe(200);
        expect(await response.json()).toEqual(route.result);
        expect(auth.validateSession).toHaveBeenCalledWith(role);
        expect(service[route.handler]).toHaveBeenCalledTimes(1);
        expect(service[route.handler]).toHaveBeenCalledWith(...route.args);
      },
    );

    it.each(
      Object.values(UserRole).filter((role) => !allowedRoles.includes(role)),
    )('IT-KQC-002: denies %s before calling the service', async (role) => {
      const response = await request(route.path, `Bearer ${role}`);

      expect(response.status).toBe(403);
      expect(await response.json()).toMatchObject({ code: 'ACCESS_DENIED' });
      for (const handler of Object.values(service)) {
        expect(handler).not.toHaveBeenCalled();
      }
    });

    it('IT-KQC-003: requires a bearer session', async () => {
      const response = await request(route.path, null);

      expect(response.status).toBe(401);
      expect(await response.json()).toMatchObject({
        code: 'SESSION_TOKEN_REQUIRED',
      });
      expect(auth.validateSession).not.toHaveBeenCalled();
      expect(service[route.handler]).not.toHaveBeenCalled();
    });

    it('IT-KQC-004: rejects an invalid or expired session', async () => {
      auth.validateSession.mockRejectedValue(new NotFoundException());

      const response = await request(route.path);

      expect(response.status).toBe(401);
      expect(await response.json()).toMatchObject({ code: 'INVALID_SESSION' });
      expect(service[route.handler]).not.toHaveBeenCalled();
    });
  });

  it('IT-KQC-005: converts list pagination into an offset and limit', async () => {
    const response = await request('?page=3&limit=5');

    expect(response.status).toBe(200);
    expect(service.findAll).toHaveBeenCalledWith(10, 5);
  });

  it('IT-KQC-006: converts activeOnly=false and paginates checker history', async () => {
    const response = await request(
      `/checker/${checkerId}?activeOnly=false&page=3&limit=5`,
    );

    expect(response.status).toBe(200);
    expect(service.findManyByChecker).toHaveBeenCalledWith(
      checkerId,
      false,
      10,
      5,
    );
  });

  it('IT-KQC-007: accepts activeOnly=true explicitly', async () => {
    const response = await request(`/checker/${checkerId}?activeOnly=true`);

    expect(response.status).toBe(200);
    expect(service.findManyByChecker).toHaveBeenCalledWith(
      checkerId,
      true,
      0,
      10,
    );
  });

  it.each(['', `/checker/${checkerId}`])(
    'IT-KQC-008: validates pagination and rejects unknown query fields on GET %s',
    async (path) => {
      for (const query of [
        'page=0',
        'page=1.5',
        'page=2147483648',
        'limit=0',
        'limit=101',
        'limit=abc',
        'unexpected=true',
      ]) {
        const response = await request(`${path}?${query}`);

        expect(response.status).toBe(400);
      }
      expect(service.findAll).not.toHaveBeenCalled();
      expect(service.findManyByChecker).not.toHaveBeenCalled();
    },
  );

  it.each(['yes', '1', '', 'false&activeOnly=true'])(
    'IT-KQC-009: rejects invalid activeOnly=%s before calling the service',
    async (value) => {
      const response = await request(
        `/checker/${checkerId}?activeOnly=${value}`,
      );

      expect(response.status).toBe(400);
      expect(service.findManyByChecker).not.toHaveBeenCalled();
    },
  );

  it.each([
    '/invalid',
    '/ticket/invalid',
    '/ticket/invalid/latest',
    '/checker/invalid',
  ])('IT-KQC-010: rejects an invalid UUID on GET %s', async (path) => {
    const response = await request(path);

    expect(response.status).toBe(400);
    for (const handler of Object.values(service)) {
      expect(handler).not.toHaveBeenCalled();
    }
  });

  it.each([
    {
      path: `/${attemptId}`,
      handler: 'findOneUID',
      code: 'KITCHEN_TICKET_QC_ATTEMPT_NOT_FOUND',
    },
    {
      path: `/ticket/${ticketId}`,
      handler: 'findMany',
      code: 'KITCHEN_TICKET_NOT_FOUND',
    },
    {
      path: `/ticket/${ticketId}/latest`,
      handler: 'findOneLatest',
      code: 'KITCHEN_TICKET_QC_ATTEMPT_NOT_FOUND',
    },
  ] as const)(
    'IT-KQC-011: preserves service not-found errors on GET $path',
    async ({ path, handler, code }) => {
      service[handler].mockRejectedValue(new NotFoundException({ code }));

      const response = await request(path);

      expect(response.status).toBe(404);
      expect(await response.json()).toMatchObject({ code });
    },
  );

  it('IT-KQC-012: returns an empty history when a ticket has no attempts', async () => {
    service.findMany.mockResolvedValue([]);

    const response = await request(`/ticket/${ticketId}`);

    expect(response.status).toBe(200);
    expect(await response.json()).toEqual([]);
  });

  it('IT-KQC-013: returns an empty result when a checker has no matching attempts', async () => {
    service.findManyByChecker.mockResolvedValue({ qcAttempts: [], total: 0 });

    const response = await request(`/checker/${checkerId}`);

    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({ qcAttempts: [], total: 0 });
  });
});
