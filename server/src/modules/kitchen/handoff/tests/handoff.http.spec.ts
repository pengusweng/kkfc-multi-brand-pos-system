import {
  BadRequestException,
  INestApplication,
  NotFoundException,
  ValidationPipe,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import { AuthService } from '../../../auth/auth.service';
import { HandoffController } from '../handoff.controller';
import { HandoffService } from '../handoff.service';

describe('Handoff list HTTP endpoints', () => {
  const result = {
    handoffs: [
      {
        handoff_id: '00000000-0000-4000-8000-000000000001',
        kitchen_ticket_id: '00000000-0000-4000-8000-000000000002',
        actor_id: '00000000-0000-4000-8000-000000000003',
        img_urls: ['https://files.example.test/handoff.png?signature=test'],
        created_at: '2026-11-03T04:00:00.000Z',
      },
    ],
    total: 21,
  };
  const allowedRoles: UserRole[] = [UserRole.SUPERADMIN, UserRole.KITCHEN_HEAD];
  const auth = { validateSession: jest.fn() };
  const service = { findAll: jest.fn(), findManyByActor: jest.fn() };
  const routes = [
    { path: '', method: 'findAll', prefix: [] },
    {
      path: `/actor/${result.handoffs[0].actor_id}`,
      method: 'findManyByActor',
      prefix: [result.handoffs[0].actor_id],
    },
  ] as const;
  let app: INestApplication;
  let url: string;

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [HandoffController],
      providers: [
        { provide: HandoffService, useValue: service },
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
    url = `${await app.getUrl()}/api/handoff`;
  });

  beforeEach(() => {
    jest.resetAllMocks();
    auth.validateSession.mockImplementation((role: UserRole) =>
      Promise.resolve({
        user: { user_id: result.handoffs[0].actor_id, role },
      }),
    );
    for (const route of routes) {
      service[route.method].mockResolvedValue(result);
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

  describe.each(routes)('GET /handoff$path', (route) => {
    it.each(allowedRoles)(
      'IT-HAND-001: allows %s and applies default pagination',
      async (role) => {
        const response = await request(route.path, `Bearer ${role}`);

        expect(response.status).toBe(200);
        expect(await response.json()).toEqual(result);
        expect(service[route.method]).toHaveBeenCalledTimes(1);
        expect(service[route.method]).toHaveBeenCalledWith(
          ...route.prefix,
          0,
          10,
        );
      },
    );

    it.each(
      Object.values(UserRole).filter((role) => !allowedRoles.includes(role)),
    )('IT-HAND-002: denies %s before calling the service', async (role) => {
      const response = await request(route.path, `Bearer ${role}`);

      expect(response.status).toBe(403);
      expect(await response.json()).toMatchObject({ code: 'ACCESS_DENIED' });
      expect(service[route.method]).not.toHaveBeenCalled();
    });

    it('IT-HAND-003: requires a bearer session', async () => {
      const response = await request(route.path, null);

      expect(response.status).toBe(401);
      expect(auth.validateSession).not.toHaveBeenCalled();
      expect(service[route.method]).not.toHaveBeenCalled();
    });

    it('IT-HAND-004: rejects invalid or expired sessions', async () => {
      auth.validateSession.mockRejectedValue(new NotFoundException());

      const response = await request(route.path);

      expect(response.status).toBe(401);
      expect(await response.json()).toMatchObject({ code: 'INVALID_SESSION' });
      expect(service[route.method]).not.toHaveBeenCalled();
    });

    it('IT-HAND-005: converts page and limit into an offset and take', async () => {
      const response = await request(`${route.path}?page=3&limit=5`);

      expect(response.status).toBe(200);
      expect(service[route.method]).toHaveBeenCalledWith(
        ...route.prefix,
        10,
        5,
      );
    });

    it.each([
      '?page=0',
      '?page=-1',
      '?page=1.5',
      '?page=invalid',
      '?page=2147483648',
      '?limit=0',
      '?limit=101',
      '?limit=invalid',
      '?unknown=true',
    ])('IT-HAND-006: rejects invalid query %s', async (query) => {
      const response = await request(`${route.path}${query}`);

      expect(response.status).toBe(400);
      expect(service[route.method]).not.toHaveBeenCalled();
    });

    it('IT-HAND-007: preserves totals on an empty page', async () => {
      service[route.method].mockResolvedValue({ handoffs: [], total: 21 });

      const response = await request(`${route.path}?page=6&limit=5`);

      expect(response.status).toBe(200);
      expect(await response.json()).toEqual({ handoffs: [], total: 21 });
      expect(service[route.method]).toHaveBeenCalledWith(
        ...route.prefix,
        25,
        5,
      );
    });

    it('IT-HAND-008: preserves an unsupported-offset service error', async () => {
      service[route.method].mockRejectedValue(
        new BadRequestException({ code: 'PAGINATION_UNSUPPORTED_RANGE' }),
      );

      const response = await request(`${route.path}?page=2147483647&limit=100`);

      expect(response.status).toBe(400);
      expect(await response.json()).toMatchObject({
        code: 'PAGINATION_UNSUPPORTED_RANGE',
      });
      expect(service[route.method]).toHaveBeenCalledWith(
        ...route.prefix,
        214_748_364_600,
        100,
      );
    });
  });

  it('IT-HAND-009: rejects an invalid actor UUID before calling the service', async () => {
    const response = await request('/actor/invalid');

    expect(response.status).toBe(400);
    expect(service.findManyByActor).not.toHaveBeenCalled();
    expect(service.findAll).not.toHaveBeenCalled();
  });
});
