import {
  INestApplication,
  NotFoundException,
  ValidationPipe,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { QcRejectionReason, UserRole } from '@prisma/client';
import { PrismaService } from '../../../../shared/prisma/prisma.service';
import { AuthModule } from '../../../auth/auth.module';
import { AuthService } from '../../../auth/auth.service';
import { PinModule } from '../../../pin/pin.module';
import { OrderItemQcRejectionModule } from '../order-item-qc-rejection.module';
import { OrderItemQcRejectionService } from '../order-item-qc-rejection.service';

describe('Order item QC rejection retrieval HTTP endpoints', () => {
  const rejectionId = '00000000-0000-4000-8000-000000000001';
  const attemptId = '00000000-0000-4000-8000-000000000002';
  const orderItemId = '00000000-0000-4000-8000-000000000003';
  const rejection = {
    rejection_id: rejectionId,
    qc_attempt_id: attemptId,
    order_item_id: orderItemId,
    portion_number: 1,
    rejection_reason: QcRejectionReason.INCOMPLETE,
    description: 'Portion failed inspection.',
    rejected_at: '2026-11-03T04:00:00.000Z',
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
    findOne: jest.fn(),
    findManyByAttemptId: jest.fn(),
    findManyByOrderItemId: jest.fn(),
  };
  const routes = [
    {
      path: `/${rejectionId}`,
      handler: 'findOne',
      id: rejectionId,
      result: rejection,
    },
    {
      path: `/attempt/${attemptId}`,
      handler: 'findManyByAttemptId',
      id: attemptId,
      result: [rejection],
    },
    {
      path: `/order-item/${orderItemId}`,
      handler: 'findManyByOrderItemId',
      id: orderItemId,
      result: [rejection],
    },
  ] as const;
  let app: INestApplication;
  let url: string;

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      imports: [AuthModule, PinModule, OrderItemQcRejectionModule],
    })
      .overrideProvider(OrderItemQcRejectionService)
      .useValue(service)
      .overrideProvider(AuthService)
      .useValue(auth)
      .overrideProvider(PrismaService)
      .useValue({})
      .compile();
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
    url = `${await app.getUrl()}/api/order-item-qc-rejection`;
  });

  beforeEach(() => {
    jest.resetAllMocks();
    auth.validateSession.mockImplementation((role: UserRole) =>
      Promise.resolve({ user: { user_id: 'user', role } }),
    );
    for (const route of routes) {
      service[route.handler].mockResolvedValue(route.result);
    }
  });

  afterAll(async () => app?.close());

  function request(
    path: string,
    authorization: string | null = `Bearer ${UserRole.KITCHEN_HEAD}`,
    method = 'GET',
  ) {
    return fetch(`${url}${path}`, {
      method,
      headers: authorization === null ? {} : { Authorization: authorization },
    });
  }

  describe.each(routes)('GET $path', (route) => {
    it.each(allowedRoles)(
      'IT-QCR-001: allows %s and forwards the ID',
      async (role) => {
        const response = await request(route.path, `Bearer ${role}`);

        expect(response.status).toBe(200);
        expect(await response.json()).toEqual(route.result);
        expect(service[route.handler]).toHaveBeenCalledWith(route.id);
      },
    );

    it.each(
      Object.values(UserRole).filter((role) => !allowedRoles.includes(role)),
    )('IT-QCR-002: denies %s before calling the service', async (role) => {
      const response = await request(route.path, `Bearer ${role}`);

      expect(response.status).toBe(403);
      expect(service[route.handler]).not.toHaveBeenCalled();
    });

    it('IT-QCR-003: requires a bearer session', async () => {
      const response = await request(route.path, null);

      expect(response.status).toBe(401);
      expect(service[route.handler]).not.toHaveBeenCalled();
    });

    it('IT-QCR-004: rejects invalid or expired sessions', async () => {
      auth.validateSession.mockRejectedValue(new NotFoundException());

      const response = await request(route.path);

      expect(response.status).toBe(401);
      expect(service[route.handler]).not.toHaveBeenCalled();
    });
  });

  it.each(['/invalid', '/attempt/invalid', '/order-item/invalid'])(
    'IT-QCR-005: rejects invalid UUIDs on GET %s',
    async (path) => {
      const response = await request(path);

      expect(response.status).toBe(400);
      for (const handler of Object.values(service)) {
        expect(handler).not.toHaveBeenCalled();
      }
    },
  );

  it('IT-QCR-006: preserves the standard rejection not-found response', async () => {
    service.findOne.mockRejectedValue(
      new NotFoundException({ code: 'ORDER_ITEM_QC_REJECTION_NOT_FOUND' }),
    );

    const response = await request(`/${rejectionId}`);

    expect(response.status).toBe(404);
    expect(await response.json()).toMatchObject({
      code: 'ORDER_ITEM_QC_REJECTION_NOT_FOUND',
    });
  });

  it.each([
    { path: `/attempt/${attemptId}`, handler: 'findManyByAttemptId' },
    { path: `/order-item/${orderItemId}`, handler: 'findManyByOrderItemId' },
  ] as const)(
    'IT-QCR-007: returns an empty list on GET $path',
    async ({ path, handler }) => {
      service[handler].mockResolvedValue([]);

      const response = await request(path);

      expect(response.status).toBe(200);
      expect(await response.json()).toEqual([]);
    },
  );

  it.each(['POST', 'PUT', 'PATCH', 'DELETE'])(
    'IT-QCR-008: does not expose a %s endpoint',
    async (method) => {
      const response = await request(`/${rejectionId}`, undefined, method);

      expect(response.status).toBe(404);
      for (const handler of Object.values(service)) {
        expect(handler).not.toHaveBeenCalled();
      }
    },
  );
});
