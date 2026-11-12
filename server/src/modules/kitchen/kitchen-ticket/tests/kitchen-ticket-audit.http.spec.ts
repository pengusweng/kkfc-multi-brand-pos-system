import { ConflictException, INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import {
  auditPipelineProviders,
  createAuditSpy,
} from '../../../../shared/testing/audit.testing';
import { AuthService } from '../../../auth/auth.service';
import { KitchenTicketController } from '../kitchen-ticket.controller';
import { KitchenTicketService } from '../kitchen-ticket.service';

const actorId = '11111111-1111-4111-8111-111111111111';
const ticketId = '22222222-2222-4222-8222-222222222222';
const cookId = '33333333-3333-4333-8333-333333333333';

describe('Kitchen ticket audit logging', () => {
  let app: INestApplication;
  let url: string;
  let role: UserRole;
  const audit = createAuditSpy();
  const tickets = {
    findMany: jest.fn(),
    assignPreparer: jest.fn(),
    assignChecker: jest.fn(),
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
      controllers: [KitchenTicketController],
      providers: [
        { provide: KitchenTicketService, useValue: tickets },
        { provide: AuthService, useValue: auth },
        ...auditPipelineProviders(audit),
      ],
    }).compile();
    app = module.createNestApplication();
    app.useLogger(false);
    app.setGlobalPrefix('api');
    await app.listen(0);
    url = `${await app.getUrl()}/api/kitchen-ticket`;
  });

  afterAll(async () => app.close());

  beforeEach(() => {
    role = UserRole.KITCHEN_HEAD;
    audit.create.mockClear().mockResolvedValue({});
    for (const mock of Object.values(tickets)) mock.mockReset();
  });

  function call(method: string, path: string, body?: unknown) {
    return fetch(`${url}${path}`, {
      method,
      headers: {
        Authorization: 'Bearer token',
        'Content-Type': 'application/json',
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
  }

  it('IT-KT-016: Given a kitchen head, When a preparer and a checker are assigned, Then audit each assignment against the ticket', async () => {
    tickets.assignPreparer.mockResolvedValue({ kitchen_ticket_id: ticketId });
    tickets.assignChecker.mockResolvedValue({ kitchen_ticket_id: ticketId });

    const preparer = await call('PATCH', `/${ticketId}/preparer`, {
      preparer_id: cookId,
    });
    const checker = await call('PATCH', `/${ticketId}/checker`, {
      checker_id: actorId,
    });

    expect([preparer.status, checker.status]).toEqual([200, 200]);
    expect(audit.rows()).toEqual([
      expect.objectContaining({
        actor_id: actorId,
        action: 'KITCHEN_TICKET_PREPARER_ASSIGNED',
        entity_type: 'kitchen_tickets',
        entity_id: ticketId,
        outcome: 'SUCCESS',
      }),
      expect.objectContaining({
        action: 'KITCHEN_TICKET_CHECKER_ASSIGNED',
        entity_id: ticketId,
        outcome: 'SUCCESS',
      }),
    ]);
  });

  it("IT-KT-017: Given a claimed ticket, kitchen staff and today's board, When tickets are claimed and read, Then audit the conflict and the denial but not the read", async () => {
    tickets.assignPreparer.mockRejectedValue(
      new ConflictException({
        code: 'KITCHEN_TICKET_PREPARER_ALREADY_ASSIGNED',
      }),
    );
    tickets.findMany.mockResolvedValue([]);

    const claimed = await call('PATCH', `/${ticketId}/preparer`, {
      preparer_id: cookId,
    });
    role = UserRole.KITCHEN_STAFF;
    const board = await call('GET', '/today');
    const checker = await call('PATCH', `/${ticketId}/checker`, {
      checker_id: actorId,
    });

    expect([claimed.status, board.status, checker.status]).toEqual([
      409, 200, 403,
    ]);
    expect(tickets.assignChecker).not.toHaveBeenCalled();
    expect(audit.rows()).toEqual([
      expect.objectContaining({
        action: 'KITCHEN_TICKET_PREPARER_ASSIGNED',
        outcome: 'FAILED',
        reason: 'KITCHEN_TICKET_PREPARER_ALREADY_ASSIGNED',
      }),
      expect.objectContaining({
        action: 'KITCHEN_TICKET_CHECKER_ASSIGNED',
        entity_id: ticketId,
        outcome: 'DENIED',
        reason: 'ACCESS_DENIED',
      }),
    ]);
  });
});
