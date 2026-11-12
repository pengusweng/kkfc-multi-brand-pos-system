import {
  INestApplication,
  NotFoundException,
  ValidationPipe,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import { AuthService } from '../../auth/auth.service';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import { AuditController } from '../audit.controller';
import { AuditRepository } from '../audit.repository';
import { AuditService } from '../audit.service';

describe('Audit list HTTP API', () => {
  let app: INestApplication;
  let url: string;
  const auth = { validateSession: jest.fn() };
  const prisma = {
    auditLog: { findMany: jest.fn(), count: jest.fn() },
    $transaction: jest.fn(),
  };

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [AuditController],
      providers: [
        AuditService,
        AuditRepository,
        { provide: AuthService, useValue: auth },
        { provide: PrismaService, useValue: prisma },
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
    url = `${await app.getUrl()}/api/audit-logs`;
  });

  beforeEach(() => {
    jest.resetAllMocks();
    auth.validateSession.mockResolvedValue({
      user: { role: UserRole.SUPERADMIN },
    });
    prisma.auditLog.findMany.mockResolvedValue([]);
    prisma.auditLog.count.mockResolvedValue(0);
    prisma.$transaction.mockImplementation((queries: Promise<unknown>[]) =>
      Promise.all(queries),
    );
  });

  afterAll(async () => app?.close());

  const headers = { Authorization: 'Bearer test-session' };

  it('IT-AUDIT-001: returns an empty paginated list with stable newest-first ordering', async () => {
    const response = await fetch(url, { headers });
    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({
      data: [],
      meta: {
        page: 1,
        limit: 10,
        total: 0,
        totalPages: 0,
        counts: { all: 0, SUCCESS: 0, DENIED: 0, FAILED: 0 },
      },
    });
    expect(prisma.auditLog.findMany).toHaveBeenCalledWith({
      where: {},
      skip: 0,
      take: 10,
      select: {
        audit_log_id: true,
        actor_id: true,
        action: true,
        entity_type: true,
        entity_id: true,
        outcome: true,
        reason: true,
        before_data: true,
        after_data: true,
        request_id: true,
        created_at: true,
        actor: {
          select: {
            username: true,
            first_name: true,
            last_name: true,
            role: true,
          },
        },
      },
      orderBy: [{ created_at: 'desc' }, { audit_log_id: 'asc' }],
    });
  });

  it('IT-AUDIT-018: returns the actor display identity, or null for anonymous rows', async () => {
    const actor = {
      username: 'msantos',
      first_name: 'Maria',
      last_name: 'Santos',
      role: UserRole.MANAGER,
    };
    const logs = [
      { audit_log_id: 'log-1', actor_id: 'user-1', actor },
      { audit_log_id: 'log-2', actor_id: null, actor: null },
    ];
    prisma.auditLog.findMany.mockResolvedValue(logs);
    prisma.auditLog.count.mockResolvedValue(2);
    const response = await fetch(url, { headers });
    expect(response.status).toBe(200);
    expect(((await response.json()) as { data: unknown }).data).toEqual(logs);
    const [[query]] = prisma.auditLog.findMany.mock.calls as [
      [{ select: { actor: { select: Record<string, boolean> } } }],
    ];
    // Credentials, status and timestamps never leave the users table.
    expect(Object.keys(query.select.actor.select).sort()).toEqual([
      'first_name',
      'last_name',
      'role',
      'username',
    ]);
  });

  const COUNTS = { SUCCESS: 4, DENIED: 2, FAILED: 1 };
  const countByOutcome = () =>
    prisma.auditLog.count.mockImplementation(
      ({ where }: { where: { outcome: keyof typeof COUNTS } }) =>
        Promise.resolve(COUNTS[where.outcome]),
    );

  it.each([
    ['action=ORDER_CONFIRMED', { action: 'ORDER_CONFIRMED' }, undefined, 7],
    ['outcome=SUCCESS', {}, 'SUCCESS', 4],
    ['outcome=DENIED', {}, 'DENIED', 2],
    ['outcome=FAILED', {}, 'FAILED', 1],
    [
      'action=ORDER_CONFIRMED&outcome=SUCCESS',
      { action: 'ORDER_CONFIRMED' },
      'SUCCESS',
      4,
    ],
  ])(
    'IT-AUDIT-002: filters records and counts every outcome under the other filters: %s',
    async (query, base, outcome, total) => {
      const logs = [{ audit_log_id: 'log-1', action: 'ORDER_CONFIRMED' }];
      prisma.auditLog.findMany.mockResolvedValue(logs);
      countByOutcome();
      const response = await fetch(`${url}?page=2&limit=5&${query}`, {
        headers,
      });
      expect(response.status).toBe(200);
      expect(await response.json()).toEqual({
        data: logs,
        meta: {
          page: 2,
          limit: 5,
          total,
          totalPages: Math.ceil(total / 5),
          counts: { all: 7, ...COUNTS },
        },
      });
      expect(prisma.auditLog.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { ...base, ...(outcome ? { outcome } : {}) },
          skip: 5,
          take: 5,
        }),
      );
      // Counts ignore the outcome filter so every outcome tab can be labelled.
      for (const value of ['SUCCESS', 'DENIED', 'FAILED']) {
        expect(prisma.auditLog.count).toHaveBeenCalledWith({
          where: { ...base, outcome: value },
        });
      }
      expect(prisma.$transaction).toHaveBeenCalledWith(expect.any(Array), {
        isolationLevel: 'RepeatableRead',
      });
    },
  );

  it('IT-AUDIT-019: searches actor names and limits to an inclusive Asia/Manila date range', async () => {
    countByOutcome();
    const response = await fetch(
      `${url}?search=%20ana%20rey%20&from=2026-11-01&to=2026-11-12`,
      { headers },
    );
    expect(response.status).toBe(200);
    const actorMatches = (term: string) => ({
      actor: {
        is: {
          OR: [
            { username: { contains: term, mode: 'insensitive' } },
            { first_name: { contains: term, mode: 'insensitive' } },
            { last_name: { contains: term, mode: 'insensitive' } },
          ],
        },
      },
    });
    expect(prisma.auditLog.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: {
          // Manila midnight on the 1st through the midnight after the 12th.
          created_at: {
            gte: new Date('2026-10-31T16:00:00.000Z'),
            lt: new Date('2026-11-12T16:00:00.000Z'),
          },
          AND: [actorMatches('ana'), actorMatches('rey')],
        },
      }),
    );
  });

  it.each([
    ['from only', 'from=2026-11-12', { gte: new Date('2026-11-11T16:00:00Z') }],
    ['to only', 'to=2026-11-12', { lt: new Date('2026-11-12T16:00:00Z') }],
    [
      'a single day',
      'from=2026-11-12&to=2026-11-12',
      {
        gte: new Date('2026-11-11T16:00:00Z'),
        lt: new Date('2026-11-12T16:00:00Z'),
      },
    ],
  ])(
    'IT-AUDIT-020: applies an open-ended or single-day date range: %s',
    async (_label, query, createdAt) => {
      countByOutcome();
      expect((await fetch(`${url}?${query}`, { headers })).status).toBe(200);
      expect(prisma.auditLog.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: { created_at: createdAt } }),
      );
    },
  );

  it('IT-AUDIT-021: treats a blank search as no search', async () => {
    countByOutcome();
    expect((await fetch(`${url}?search=%20%20`, { headers })).status).toBe(200);
    expect(prisma.auditLog.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: {} }),
    );
  });

  it.each(
    Object.values(UserRole).filter((role) => role !== UserRole.SUPERADMIN),
  )('IT-AUDIT-003: denies %s before querying audit records', async (role) => {
    auth.validateSession.mockResolvedValue({ user: { role } });
    expect((await fetch(url, { headers })).status).toBe(403);
    expect(prisma.auditLog.findMany).not.toHaveBeenCalled();
  });

  it('IT-AUDIT-004: requires authentication', async () => {
    expect((await fetch(url)).status).toBe(401);
    expect(prisma.auditLog.findMany).not.toHaveBeenCalled();
  });

  it('IT-AUDIT-005: rejects expired or invalid sessions', async () => {
    auth.validateSession.mockRejectedValue(new NotFoundException());
    expect((await fetch(url, { headers })).status).toBe(401);
    expect(prisma.auditLog.findMany).not.toHaveBeenCalled();
  });

  it.each([
    'outcome=INVALID',
    'outcome=success',
    'action=',
    'action=%20',
    `action=${'a'.repeat(101)}`,
    'action=A&action=B',
    'outcome=SUCCESS&outcome=DENIED',
    'page=1&page=2',
    'limit=10&limit=20',
    'page=NaN',
    'limit=Infinity',
    'page=0',
    'page=1.5',
    'limit=101',
    'limit=0',
    'page=2147483647&limit=100',
    'unknown=true',
    `search=${'a'.repeat(101)}`,
    'search=a&search=b',
    'from=2026-11-31',
    'from=2026/11/01',
    'from=11-01-2026',
    'to=2026-13-01',
    'to=today',
    'from=2026-11-12&to=2026-11-01',
  ])('IT-AUDIT-006: rejects invalid queries: %s', async (query) => {
    expect((await fetch(`${url}?${query}`, { headers })).status).toBe(400);
    expect(prisma.auditLog.findMany).not.toHaveBeenCalled();
  });

  it.each(['POST', 'PUT', 'PATCH', 'DELETE'])(
    'IT-AUDIT-007: exposes no %s endpoint for audit records',
    async (method) => {
      for (const path of ['', '/00000000-0000-4000-8000-000000000001']) {
        expect((await fetch(`${url}${path}`, { method, headers })).status).toBe(
          404,
        );
      }
      expect(prisma.auditLog.findMany).not.toHaveBeenCalled();
    },
  );
});
