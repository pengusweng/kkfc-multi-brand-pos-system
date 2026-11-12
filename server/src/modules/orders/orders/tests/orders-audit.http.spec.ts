import { ConflictException, INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import {
  auditPipelineProviders,
  createAuditSpy,
} from '../../../../shared/testing/audit.testing';
import { AuthService } from '../../../auth/auth.service';
import { KitchenTicketChanges } from '../../../kitchen/kitchen-ticket/kitchen-ticket-changes.service';
import { OrdersController } from '../orders.controller';
import { OrdersService } from '../orders.service';

const actorId = '11111111-1111-4111-8111-111111111111';
const brandId = '22222222-2222-4222-8222-222222222222';
const orderId = '33333333-3333-4333-8333-333333333333';

// Order DTO validation is covered by orders.http.spec.ts; this spec only
// checks which audit rows each order action produces.
describe('Orders audit logging', () => {
  let app: INestApplication;
  let url: string;
  let role: UserRole;
  const audit = createAuditSpy();
  const orders = {
    findAll: jest.fn(),
    findOne: jest.fn(),
    create: jest.fn(),
    verify: jest.fn(),
    confirm: jest.fn(),
    cancelDraft: jest.fn(),
  };
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
      controllers: [OrdersController],
      providers: [
        KitchenTicketChanges,
        { provide: OrdersService, useValue: orders },
        { provide: AuthService, useValue: auth },
        ...auditPipelineProviders(audit),
      ],
    }).compile();
    app = module.createNestApplication();
    app.useLogger(false);
    app.setGlobalPrefix('api');
    await app.listen(0);
    url = `${await app.getUrl()}/api/brands/${brandId}/orders`;
  });

  afterAll(async () => app.close());

  beforeEach(() => {
    role = UserRole.CASHIER_STAFF;
    audit.create.mockClear().mockResolvedValue({});
    for (const mock of Object.values(orders)) mock.mockReset();
  });

  function call(method: string, path = '', body: unknown = {}) {
    return fetch(`${url}${path}`, {
      method,
      headers: {
        Authorization: 'Bearer token',
        'Content-Type': 'application/json',
      },
      body: method === 'GET' ? undefined : JSON.stringify(body),
    });
  }

  it('IT-ORD-040: Given a cashier, When an order is created, verified, confirmed and a draft is cancelled, Then audit every action except the read-only verify', async () => {
    orders.create.mockResolvedValue({ order_id: orderId });
    orders.verify.mockResolvedValue({ order_id: orderId, valid: true });
    orders.confirm.mockResolvedValue({ order_id: orderId });
    orders.cancelDraft.mockResolvedValue({ order_id: orderId });

    const statuses = [
      (await call('POST')).status,
      (await call('POST', `/${orderId}/verify`)).status,
      (await call('POST', `/${orderId}/confirm`)).status,
      (await call('POST', `/${orderId}/cancel`)).status,
    ];

    expect(statuses).toEqual([201, 200, 200, 200]);
    expect(audit.rows()).toEqual([
      expect.objectContaining({
        actor_id: actorId,
        action: 'ORDER_CREATED',
        entity_type: 'orders',
        entity_id: orderId,
        outcome: 'SUCCESS',
      }),
      expect.objectContaining({
        action: 'ORDER_CONFIRMED',
        entity_id: orderId,
        outcome: 'SUCCESS',
      }),
      expect.objectContaining({
        action: 'ORDER_CANCELLED',
        entity_id: orderId,
        outcome: 'SUCCESS',
      }),
    ]);
  });

  it('IT-ORD-041: Given a duplicate platform order and a non-draft order, When they are created and confirmed, Then audit FAILED rows with the order codes', async () => {
    orders.create.mockRejectedValue(
      new ConflictException({ code: 'DUPLICATE_PLATFORM_ORDER' }),
    );
    orders.confirm.mockRejectedValue(
      new ConflictException({ code: 'ORDER_NOT_DRAFT' }),
    );

    const created = await call('POST');
    const confirmed = await call('POST', `/${orderId}/confirm`);

    expect([created.status, confirmed.status]).toEqual([409, 409]);
    expect(audit.rows()).toEqual([
      expect.objectContaining({
        action: 'ORDER_CREATED',
        entity_id: null,
        outcome: 'FAILED',
        reason: 'DUPLICATE_PLATFORM_ORDER',
      }),
      expect.objectContaining({
        action: 'ORDER_CONFIRMED',
        entity_id: orderId,
        outcome: 'FAILED',
        reason: 'ORDER_NOT_DRAFT',
      }),
    ]);
  });

  it('IT-ORD-042: Given kitchen staff and routine order reads, When orders are read and an order is created, Then only the role denial is audited', async () => {
    orders.findAll.mockResolvedValue({ data: [], meta: {} });
    orders.findOne.mockResolvedValue({ order_id: orderId });

    const list = await call('GET');
    role = UserRole.KITCHEN_STAFF;
    const view = await call('GET', `/${orderId}`);
    const create = await call('POST');

    expect([list.status, view.status, create.status]).toEqual([200, 200, 403]);
    expect(orders.create).not.toHaveBeenCalled();
    expect(audit.rows()).toEqual([
      expect.objectContaining({
        actor_id: actorId,
        action: 'ORDER_CREATED',
        outcome: 'DENIED',
        reason: 'ACCESS_DENIED',
      }),
    ]);
  });
});
