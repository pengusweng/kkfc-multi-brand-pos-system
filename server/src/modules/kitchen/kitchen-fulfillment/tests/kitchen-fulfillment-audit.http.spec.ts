import {
  ConflictException,
  ForbiddenException,
  INestApplication,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import {
  auditPipelineProviders,
  createAuditSpy,
} from '../../../../shared/testing/audit.testing';
import { AssetsService } from '../../../assets/assets.service';
import { AuthService } from '../../../auth/auth.service';
import { KitchenFulfillmentController } from '../kitchen-fulfillment.controller';
import { KitchenFulfillmentService } from '../kitchen-fulfillment.service';

const actorId = '11111111-1111-4111-8111-111111111111';
const ticketId = '22222222-2222-4222-8222-222222222222';
const attemptId = '33333333-3333-4333-8333-333333333333';
const brandId = '44444444-4444-4444-8444-444444444444';
const orderId = '55555555-5555-4555-8555-555555555555';
const itemId = '66666666-6666-4666-8666-666666666666';

// Request DTO validation is covered by kitchen-fulfillment.http.spec.ts; this
// spec only checks which audit rows each fulfillment step produces.
describe('Kitchen fulfillment audit logging', () => {
  let app: INestApplication;
  let url: string;
  let role: UserRole;
  const audit = createAuditSpy();
  const fulfillment = {
    acknowledge: jest.fn(),
    prepare: jest.fn(),
    forChecking: jest.fn(),
    check: jest.fn(),
    passQCAttempt: jest.fn(),
    rejectQcAttempt: jest.fn(),
    handOver: jest.fn(),
    cancel: jest.fn(),
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
      controllers: [KitchenFulfillmentController],
      providers: [
        { provide: KitchenFulfillmentService, useValue: fulfillment },
        { provide: AssetsService, useValue: { upload: jest.fn() } },
        { provide: AuthService, useValue: auth },
        ...auditPipelineProviders(audit),
      ],
    }).compile();
    app = module.createNestApplication();
    app.useLogger(false);
    app.setGlobalPrefix('api');
    await app.listen(0);
    url = `${await app.getUrl()}/api/kitchen-fulfillment`;
  });

  afterAll(async () => app.close());

  beforeEach(() => {
    role = UserRole.KITCHEN_HEAD;
    audit.create.mockClear().mockResolvedValue({});
    for (const mock of Object.values(fulfillment)) {
      mock.mockReset().mockResolvedValue({});
    }
  });

  function post(path: string, body: unknown = {}) {
    return fetch(`${url}${path}`, {
      method: 'POST',
      headers: {
        Authorization: 'Bearer token',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });
  }

  it('IT-KFUL-019: Given a kitchen head, When a ticket goes through every fulfillment step, Then audit each step against its ticket, QC attempt or order', async () => {
    const steps: Array<[string, unknown, string, string, string]> = [
      [
        `/${ticketId}/acknowledge`,
        {},
        'KITCHEN_TICKET_ACKNOWLEDGED',
        'kitchen_tickets',
        ticketId,
      ],
      [
        `/${ticketId}/prepare`,
        {},
        'KITCHEN_TICKET_PREPARATION_STARTED',
        'kitchen_tickets',
        ticketId,
      ],
      [
        `/${ticketId}/for-checking`,
        {},
        'KITCHEN_TICKET_SENT_FOR_CHECKING',
        'kitchen_tickets',
        ticketId,
      ],
      [
        `/${ticketId}/check`,
        {},
        'KITCHEN_TICKET_CHECK_STARTED',
        'kitchen_tickets',
        ticketId,
      ],
      [
        `/qc-attempts/${attemptId}/reject`,
        { rejections: [{ order_item_id: itemId, portion_number: 1 }] },
        'KITCHEN_QC_REJECTED',
        'kitchen_ticket_qc_attempts',
        attemptId,
      ],
      [
        `/qc-attempts/${attemptId}/pass`,
        {},
        'KITCHEN_QC_PASSED',
        'kitchen_ticket_qc_attempts',
        attemptId,
      ],
      [
        `/${ticketId}/hand-over`,
        { img_keys: ['uploads/handoff.png'] },
        'KITCHEN_TICKET_HANDED_OVER',
        'kitchen_tickets',
        ticketId,
      ],
      [
        `/brands/${brandId}/orders/${orderId}/cancel`,
        { cancellation_reason: 'Customer left' },
        'ORDER_CANCELLED',
        'orders',
        orderId,
      ],
    ];

    for (const [path, body] of steps) {
      expect((await post(path, body)).status).toBe(200);
    }

    expect(audit.rows()).toEqual(
      steps.map(([, , action, entity, id]): unknown =>
        expect.objectContaining({
          actor_id: actorId,
          action,
          entity_type: entity,
          entity_id: id,
          outcome: 'SUCCESS',
        }),
      ),
    );
    expect(JSON.stringify(audit.rows())).not.toContain('Customer left');
  });

  it('IT-KFUL-020: Given a ticket in the wrong status and a different preparer, When the ticket is advanced, Then audit FAILED and DENIED rows with the ticket codes', async () => {
    fulfillment.prepare.mockRejectedValue(
      new ConflictException({ code: 'KITCHEN_TICKET_INVALID_STATUS' }),
    );
    fulfillment.forChecking.mockRejectedValue(
      new ForbiddenException({ code: 'KITCHEN_TICKET_PREPARER_MISMATCH' }),
    );

    const prepare = await post(`/${ticketId}/prepare`);
    const forChecking = await post(`/${ticketId}/for-checking`);

    expect([prepare.status, forChecking.status]).toEqual([409, 403]);
    expect(audit.rows()).toEqual([
      expect.objectContaining({
        action: 'KITCHEN_TICKET_PREPARATION_STARTED',
        entity_id: ticketId,
        outcome: 'FAILED',
        reason: 'KITCHEN_TICKET_INVALID_STATUS',
      }),
      expect.objectContaining({
        action: 'KITCHEN_TICKET_SENT_FOR_CHECKING',
        entity_id: ticketId,
        outcome: 'DENIED',
        reason: 'KITCHEN_TICKET_PREPARER_MISMATCH',
      }),
    ]);
  });

  it('IT-KFUL-021: Given kitchen staff, When they pass a QC attempt or cancel a confirmed order, Then audit DENIED rows and run no fulfillment step', async () => {
    role = UserRole.KITCHEN_STAFF;

    const pass = await post(`/qc-attempts/${attemptId}/pass`);
    const cancel = await post(`/brands/${brandId}/orders/${orderId}/cancel`, {
      cancellation_reason: 'Customer left',
    });

    expect([pass.status, cancel.status]).toEqual([403, 403]);
    expect(fulfillment.passQCAttempt).not.toHaveBeenCalled();
    expect(fulfillment.cancel).not.toHaveBeenCalled();
    expect(audit.rows()).toEqual([
      expect.objectContaining({
        action: 'KITCHEN_QC_PASSED',
        entity_id: attemptId,
        outcome: 'DENIED',
        reason: 'ACCESS_DENIED',
      }),
      expect.objectContaining({
        action: 'ORDER_CANCELLED',
        entity_id: orderId,
        outcome: 'DENIED',
        reason: 'ACCESS_DENIED',
      }),
    ]);
  });
});
