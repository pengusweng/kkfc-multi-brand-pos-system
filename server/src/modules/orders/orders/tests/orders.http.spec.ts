import { OrderItemsService } from '../../order-items/order-items.service';
import { OrderItemsRepository } from '../../order-items/order-items.repository';
import {
  INestApplication,
  ConflictException,
  NotFoundException,
  ValidationPipe,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { OrderChannel, QcRejectionReason, UserRole } from '@prisma/client';
import { createHash, randomUUID } from 'node:crypto';
import { AppModule } from '../../../../app.module';
import { PrismaService } from '../../../../shared/prisma/prisma.service';
import { StorageService } from '../../../../shared/storage/storage.service';
import {
  cleanupCatalogFixture,
  createCatalogFixture,
  requireTestDatabase,
} from '../../../../shared/testing/catalog.fixture';
import { OrdersRepository } from '../orders.repository';
import { OrdersService } from '../orders.service';
import { AuthService } from '../../../auth/auth.service';
import { OrdersController } from '../orders.controller';

describe('Orders HTTP endpoints (PostgreSQL integration)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let fixture: Awaited<ReturnType<typeof createCatalogFixture>>;
  let tokens: string[];
  let url: string;
  const storage = {
    createDownloadUrl: jest.fn((key: string) =>
      Promise.resolve(`https://files.example.test/${key}`),
    ),
    putObject: jest.fn().mockResolvedValue(undefined),
  };

  beforeAll(async () => {
    requireTestDatabase();
    const module = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(StorageService)
      .useValue(storage)
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
    prisma = app.get(PrismaService);
    await prisma.$connect();
    await app.listen(0, '127.0.0.1');
    url = `${await app.getUrl()}/api`;
  });

  beforeEach(async () => {
    if (!prisma) return;
    fixture = await createCatalogFixture(prisma);
    tokens = fixture.users.map(() => randomUUID());
    await prisma.userSession.createMany({
      data: fixture.users.map((user, index) => ({
        user_id: user.user_id,
        token_hash: createHash('sha256').update(tokens[index]).digest('hex'),
        expires_at: new Date(Date.now() + 3600000),
      })),
    });
    storage.putObject.mockClear();
  });

  afterEach(async () => {
    if (fixture) await cleanupCatalogFixture(prisma, fixture);
  });
  afterAll(async () => {
    await app?.close();
  });

  function request(
    path: string,
    method = 'GET',
    body?: unknown,
    user = 0,
    pin: string | null = fixture.pin,
  ) {
    return fetch(`${url}${path}`, {
      method,
      headers: {
        ...(user >= 0 ? { Authorization: `Bearer ${tokens[user]}` } : {}),
        ...(user >= 0 && user !== 1 && method !== 'GET' && pin !== null
          ? { 'X-Action-Pin': pin }
          : {}),
        ...(body === undefined || body instanceof FormData
          ? {}
          : { 'Content-Type': 'application/json' }),
      },
      body:
        body === undefined
          ? undefined
          : body instanceof FormData
            ? body
            : JSON.stringify(body),
    });
  }

  it('IT-KT-014: Given a confirmed order, When kitchen staff claim its ticket, Then reads and assignee filters return the saved assignment', async () => {
    const order = await draft();
    const confirmed = await request(
      `/brands/${fixture.brand.brand_id}/orders/${order.order_id}/confirm`,
      'POST',
      { payment_method: 'CASH', payment_status: 'UNPAID' },
      1,
    );
    expect(confirmed.status).toBe(200);
    const body = (await confirmed.json()) as {
      kitchen_tickets_order: { kitchen_ticket_id: string };
    };
    const ticketId = body.kitchen_tickets_order.kitchen_ticket_id;
    const preparerId = fixture.users[5].user_id;
    const checkerId = fixture.users[4].user_id;
    const assignment = await request(
      `/kitchen-ticket/${ticketId}/preparer`,
      'PATCH',
      { preparer_id: preparerId },
      5,
    );
    expect(assignment.status).toBe(200);
    expect(await assignment.json()).toMatchObject({ preparer_id: preparerId });
    expect(
      (
        await request(
          `/kitchen-ticket/${ticketId}/checker`,
          'PATCH',
          { checker_id: checkerId },
          4,
        )
      ).status,
    ).toBe(200);
    expect(
      await (
        await request(`/kitchen-ticket/${ticketId}`, 'GET', undefined, 5)
      ).json(),
    ).toMatchObject({
      preparer_id: preparerId,
      checker_id: checkerId,
      status: 'QUEUED',
    });
    for (const path of [
      '/kitchen-ticket/today',
      `/kitchen-ticket/preparer/${preparerId}`,
      `/kitchen-ticket/checker/${checkerId}`,
    ]) {
      const response = await request(path, 'GET', undefined, 5);
      expect(response.status).toBe(200);
      expect(await response.json()).toEqual(
        expect.arrayContaining([
          expect.objectContaining({ kitchen_ticket_id: ticketId }),
        ]),
      );
    }
    const denied = await request(
      `/kitchen-ticket/${ticketId}/checker`,
      'PATCH',
      { checker_id: preparerId },
      5,
    );
    expect(denied.status).toBe(403);
    const duplicate = await request(
      `/kitchen-ticket/${ticketId}/preparer`,
      'PATCH',
      { preparer_id: checkerId },
      4,
    );
    expect(duplicate.status).toBe(409);
    expect(await duplicate.json()).toMatchObject({
      code: 'KITCHEN_TICKET_PREPARER_ALREADY_ASSIGNED',
    });
    expect(
      await prisma.kitchenTicket.findUniqueOrThrow({
        where: { kitchen_ticket_id: ticketId },
      }),
    ).toMatchObject({ preparer_id: preparerId, checker_id: checkerId });
  });

  it('IT-KT-015: Given a queued ticket, When two preparers race to claim it, Then exactly one assignment persists', async () => {
    const order = await draft();
    const confirmed = await request(
      `/brands/${fixture.brand.brand_id}/orders/${order.order_id}/confirm`,
      'POST',
      { payment_method: 'CASH', payment_status: 'UNPAID' },
      1,
    );
    expect(confirmed.status).toBe(200);
    const body = (await confirmed.json()) as {
      kitchen_tickets_order: { kitchen_ticket_id: string };
    };
    const ticket = body.kitchen_tickets_order;
    const responses = await Promise.all(
      [4, 5].map((user) =>
        request(
          `/kitchen-ticket/${ticket.kitchen_ticket_id}/preparer`,
          'PATCH',
          { preparer_id: fixture.users[user].user_id },
          user,
        ),
      ),
    );
    expect(
      responses.filter((response) => response.status === 200),
    ).toHaveLength(1);
    // A loser can fail the service precheck (409) or the guarded Prisma write (404).
    expect([404, 409]).toContain(
      responses.find((response) => response.status !== 200)?.status,
    );
    const winner = (await responses
      .find((response) => response.status === 200)!
      .json()) as { preparer_id: string };
    expect(
      await prisma.kitchenTicket.findUniqueOrThrow({
        where: { kitchen_ticket_id: ticket.kitchen_ticket_id },
      }),
    ).toMatchObject({ preparer_id: winner.preparer_id });
  });
  it.each(['verify', 'confirm', 'cancel'])(
    'IT-ORD-018: rejects a wrong-brand order URL for %s',
    async (operation) => {
      const body = await draft();
      const response = await request(
        `/brands/${fixture.otherBrand.brand_id}/orders/${body.order_id}/${operation}`,
        'POST',
        operation === 'cancel'
          ? { cancellation_reason: 'Wrong brand' }
          : { payment_method: 'CASH', payment_status: 'PAID' },
        1,
      );
      expect(response.status).toBe(404);
      expect(
        (
          await prisma.order.findUniqueOrThrow({
            where: { order_id: body.order_id },
          })
        ).status,
      ).toBe('DRAFT');
    },
  );

  async function json(response: Response): Promise<Record<string, unknown>> {
    return (await response.json()) as Record<string, unknown>;
  }
  function channelBody(order_channel: OrderChannel = 'GRABFOOD') {
    return {
      menu_item_id: fixture.item.menu_item_id,
      order_channel,
      price: 120,
    };
  }
  async function channel(order_channel: OrderChannel = 'GRABFOOD') {
    return prisma.menuItemChannel.create({ data: channelBody(order_channel) });
  }
  function orderBody(order_channel: OrderChannel = 'TAKEAWAY') {
    return {
      order_id: randomUUID(),
      order_channel,
      lines: [
        {
          menu_item_id: fixture.item.menu_item_id,
          quantity: 2,
          modifier_ids: [fixture.modifier.modifier_id],
        },
      ],
      ...(order_channel === 'DINE_IN' ? { table_reference: 'T1' } : {}),
      ...(['GRABFOOD', 'FOODPANDA'].includes(order_channel)
        ? {
            merchant_store_reference: 'test-store',
            external_order_reference: randomUUID(),
          }
        : {}),
    };
  }
  function ordersPath() {
    return `/brands/${fixture.brand.brand_id}/orders`;
  }
  const payment = { payment_method: 'CASH', payment_status: 'UNPAID' };
  async function draft(order_channel: OrderChannel = 'TAKEAWAY') {
    const body = orderBody(order_channel);
    expect((await request(ordersPath(), 'POST', body, 1)).status).toBe(201);
    return body;
  }
  async function savedOrder(orderId: string) {
    return prisma.order.findUniqueOrThrow({
      where: { order_id: orderId },
      include: {
        order_items_order: {
          include: { order_item_modifiers_order_item: true },
        },
        kitchen_tickets_order: true,
      },
    });
  }

  async function confirmedOrder() {
    const body = await draft();
    expect(
      (
        await request(
          `${ordersPath()}/${body.order_id}/confirm`,
          'POST',
          payment,
          1,
        )
      ).status,
    ).toBe(200);
    return savedOrder(body.order_id);
  }

  it('IT-KFUL-015: completes preparation rejection rework QC approval and image-free handover through authenticated endpoints', async () => {
    const order = await confirmedOrder();
    const ticketId = order.kitchen_tickets_order!.kitchen_ticket_id;
    const ticketPath = `/kitchen-fulfillment/${ticketId}`;
    const preparerId = fixture.users[5].user_id;
    const checkerId = fixture.users[4].user_id;
    expect(
      (
        await request(
          `/kitchen-ticket/${ticketId}/preparer`,
          'PATCH',
          { preparer_id: preparerId },
          5,
        )
      ).status,
    ).toBe(200);
    expect(
      (
        await request(
          `/kitchen-ticket/${ticketId}/checker`,
          'PATCH',
          { checker_id: checkerId },
          4,
        )
      ).status,
    ).toBe(200);

    const acknowledged = await request(
      `${ticketPath}/acknowledge`,
      'POST',
      undefined,
      5,
    );
    expect(acknowledged.status).toBe(200);
    expect(await json(acknowledged)).toMatchObject({ status: 'ACKNOWLEDGED' });
    const prepared = await request(
      `${ticketPath}/prepare`,
      'POST',
      undefined,
      5,
    );
    expect(prepared.status).toBe(200);
    expect(await json(prepared)).toMatchObject({
      ticket: { status: 'PREPARING' },
      order: { status: 'PREPARING' },
    });
    expect(
      (await request(`${ticketPath}/for-checking`, 'POST', undefined, 5))
        .status,
    ).toBe(200);

    const checked = await request(`${ticketPath}/check`, 'POST', undefined, 4);
    expect(checked.status).toBe(200);
    const first = (await checked.json()) as {
      ticket: { status: string };
      attempt: {
        qc_attempt_id: string;
        attempt_number: number;
        status: string;
      };
    };
    expect(first).toMatchObject({
      ticket: { status: 'CHECKING' },
      attempt: { status: 'IN_PROGRESS', attempt_number: 1 },
    });
    const rejected = await request(
      `/kitchen-fulfillment/qc-attempts/${first.attempt.qc_attempt_id}/reject`,
      'POST',
      {
        rejections: [
          {
            order_item_id: order.order_items_order[0].order_item_id,
            portion_number: 1,
            rejection_reason: Object.values(QcRejectionReason)[0],
            description: 'Portion needs rework.',
          },
        ],
      },
      4,
    );
    expect(rejected.status).toBe(200);
    expect(await json(rejected)).toMatchObject({
      ticket: { status: 'REWORKING', preparer_id: preparerId },
      attempt: { status: 'FAILED' },
      rejections: [{ portion_number: 1 }],
    });

    expect(
      (await request(`${ticketPath}/for-checking`, 'POST', undefined, 5))
        .status,
    ).toBe(200);
    const rechecked = await request(
      `${ticketPath}/check`,
      'POST',
      undefined,
      4,
    );
    expect(rechecked.status).toBe(200);
    const second = (await rechecked.json()) as {
      attempt: { qc_attempt_id: string; attempt_number: number };
    };
    expect(second.attempt.attempt_number).toBe(2);
    const passed = await request(
      `/kitchen-fulfillment/qc-attempts/${second.attempt.qc_attempt_id}/pass`,
      'POST',
      undefined,
      4,
    );
    expect(passed.status).toBe(200);
    expect(await json(passed)).toMatchObject({
      ticket: { status: 'READY' },
      attempt: { status: 'PASSED' },
    });

    const handedOver = await request(
      `${ticketPath}/hand-over`,
      'POST',
      undefined,
      5,
    );
    expect(handedOver.status).toBe(200);
    expect(await json(handedOver)).toMatchObject({
      order: {
        status: 'COMPLETED',
        kitchen_tickets_order: { status: 'HANDED_OVER' },
      },
      handedOverTicket: { status: 'HANDED_OVER' },
    });
    const saved = await savedOrder(order.order_id);
    expect(saved.status).toBe('COMPLETED');
    expect(saved.kitchen_tickets_order?.status).toBe('HANDED_OVER');
    expect(
      await prisma.kitchenTicketQcAttempt.count({
        where: { kitchen_ticket_id: ticketId },
      }),
    ).toBe(2);
  });

  it.each([
    ['CONFIRMED', 'QUEUED'],
    ['CONFIRMED', 'ACKNOWLEDGED'],
    ['PREPARING', 'PREPARING'],
    ['PREPARING', 'FOR_CHECKING'],
    ['PREPARING', 'CHECKING'],
    ['PREPARING', 'REWORKING'],
    ['PREPARING', 'READY'],
  ] as const)(
    'IT-KFUL-001: cancels a %s order and its %s ticket atomically and preserves the original cancellation on retry',
    async (orderStatus, ticketStatus) => {
      const original = await confirmedOrder();
      await prisma.order.update({
        where: { order_id: original.order_id },
        data: { status: orderStatus },
      });
      await prisma.kitchenTicket.update({
        where: { order_id: original.order_id },
        data: { status: ticketStatus },
      });
      const path = `/kitchen-fulfillment${ordersPath()}/${original.order_id}/cancel`;
      const response = await request(
        path,
        'POST',
        { cancellation_reason: '  Customer request  ' },
        0,
      );
      expect(response.status).toBe(200);
      const result = await json(response);
      expect(result).toMatchObject({
        order: {
          status: 'CANCELLED',
          cancelled_by_id: fixture.users[0].user_id,
          cancellation_reason: 'Customer request',
          kitchen_tickets_order: { status: 'CANCELLED' },
        },
        ticket: {
          status: 'CANCELLED',
          kitchen_ticket_id: original.kitchen_tickets_order!.kitchen_ticket_id,
        },
      });
      const saved = await savedOrder(original.order_id);
      expect(saved.status).toBe('CANCELLED');
      expect(saved.kitchen_tickets_order?.status).toBe('CANCELLED');
      expect(saved.cancelled_at).toBeInstanceOf(Date);
      expect(saved.kitchen_tickets_order?.cancelled_at).toBeInstanceOf(Date);
      const retry = await request(
        path,
        'POST',
        { cancellation_reason: 'Different reason' },
        0,
      );
      expect(retry.status).toBe(200);
      expect(await json(retry)).toEqual(result);
      expect(await savedOrder(original.order_id)).toEqual(saved);
    },
  );

  it.each([
    {
      name: 'orders endpoint with a ticket',
      orderStatus: 'CONFIRMED',
      ticketStatus: 'QUEUED',
      fulfillment: false,
      wrongBrand: false,
      status: 409,
    },
    {
      name: 'handed-over ticket',
      orderStatus: 'PREPARING',
      ticketStatus: 'HANDED_OVER',
      fulfillment: true,
      wrongBrand: false,
      status: 409,
    },
    {
      name: 'completed order',
      orderStatus: 'COMPLETED',
      ticketStatus: 'READY',
      fulfillment: true,
      wrongBrand: false,
      status: 409,
    },
    {
      name: 'wrong-brand fulfillment URL',
      orderStatus: 'CONFIRMED',
      ticketStatus: 'QUEUED',
      fulfillment: true,
      wrongBrand: true,
      status: 404,
    },
  ] as const)(
    'IT-KFUL-002: rejects cancellation for $name without changing either record',
    async ({ orderStatus, ticketStatus, fulfillment, wrongBrand, status }) => {
      const original = await confirmedOrder();
      await prisma.order.update({
        where: { order_id: original.order_id },
        data: { status: orderStatus },
      });
      await prisma.kitchenTicket.update({
        where: { order_id: original.order_id },
        data: { status: ticketStatus },
      });
      const before = await savedOrder(original.order_id);
      const brand = wrongBrand
        ? fixture.otherBrand.brand_id
        : fixture.brand.brand_id;
      const path = `${fulfillment ? '/kitchen-fulfillment' : ''}/brands/${brand}/orders/${original.order_id}/cancel`;
      expect(
        (
          await request(
            path,
            'POST',
            { cancellation_reason: 'Customer request' },
            0,
          )
        ).status,
      ).toBe(status);
      expect(await savedOrder(original.order_id)).toEqual(before);
    },
  );

  it('IT-KFUL-003: rolls back ticket cancellation when order cancellation fails and safely retries', async () => {
    const original = await confirmedOrder();
    const path = `/kitchen-fulfillment${ordersPath()}/${original.order_id}/cancel`;
    const cancel = jest
      .spyOn(app.get(OrdersService), 'cancel')
      .mockRejectedValueOnce(
        new ConflictException('Injected order cancellation failure'),
      );
    try {
      expect(
        (
          await request(
            path,
            'POST',
            { cancellation_reason: 'Customer request' },
            0,
          )
        ).status,
      ).toBe(409);
      expect(await savedOrder(original.order_id)).toEqual(original);
    } finally {
      cancel.mockRestore();
    }
    expect(
      (
        await request(
          path,
          'POST',
          { cancellation_reason: 'Customer request' },
          0,
        )
      ).status,
    ).toBe(200);
    expect(
      (await savedOrder(original.order_id)).kitchen_tickets_order?.status,
    ).toBe('CANCELLED');
  });

  it('IT-KFUL-004: directs drafts to the orders endpoint and preserves draft cancellation retries', async () => {
    const body = await draft();
    const path = `${ordersPath()}/${body.order_id}/cancel`;
    expect(
      (
        await request(
          `/kitchen-fulfillment${path}`,
          'POST',
          { cancellation_reason: 'Customer request' },
          0,
        )
      ).status,
    ).toBe(409);
    expect((await savedOrder(body.order_id)).status).toBe('DRAFT');
    const cancelled = await request(
      path,
      'POST',
      { cancellation_reason: 'Customer request' },
      0,
    );
    expect(cancelled.status).toBe(200);
    const result = await json(cancelled);
    expect(result).toMatchObject({
      status: 'CANCELLED',
      kitchen_tickets_order: null,
    });
    const retry = await request(
      path,
      'POST',
      { cancellation_reason: 'Another request' },
      0,
    );
    expect(retry.status).toBe(200);
    expect(await json(retry)).toEqual(result);
  });

  it.each([
    { name: 'invalid order UUID', change: { order_id: 'invalid' } },
    { name: 'empty lines', change: { lines: [] } },
    {
      name: 'too many lines',
      change: {
        lines: Array.from({ length: 101 }, () => ({
          menu_item_id: randomUUID(),
          quantity: 1,
        })),
      },
    },
    { name: 'unknown field', change: { unexpected: true } },
    { name: 'client-supplied code', change: { order_code: 'GC-00001' } },
    ...[0, -1, 1.5, 10000].map((quantity) => ({
      name: `quantity ${quantity}`,
      change: { lines: [{ menu_item_id: randomUUID(), quantity }] },
    })),
    {
      name: 'duplicate modifiers',
      change: {
        lines: [
          {
            menu_item_id: randomUUID(),
            quantity: 1,
            modifier_ids: [fixtureId(), fixtureId()],
          },
        ],
      },
    },
    {
      name: 'too many modifiers',
      change: {
        lines: [
          {
            menu_item_id: randomUUID(),
            quantity: 1,
            modifier_ids: Array.from({ length: 101 }, () => randomUUID()),
          },
        ],
      },
    },
  ])(
    'IT-ORD-001 Given $name When posting an order Then reject without persistence',
    async ({ change }) => {
      expect(
        (await request(ordersPath(), 'POST', { ...orderBody(), ...change }, 1))
          .status,
      ).toBe(400);
      expect(
        await prisma.order.count({
          where: { brand_id: fixture.brand.brand_id },
        }),
      ).toBe(0);
      expect(
        await prisma.orderDailyCounter.count({
          where: { brand_id: fixture.brand.brand_id },
        }),
      ).toBe(0);
    },
  );

  // A constant valid UUID deliberately repeated by the duplicate-modifier case.
  function fixtureId() {
    return '00000000-0000-4000-8000-000000000001';
  }

  it.each(['verify', 'confirm'])(
    'IT-ORD-002 Given invalid UUIDs or payment fields When calling %s Then reject without changing the draft',
    async (operation) => {
      const order = await draft();
      const before = await savedOrder(order.order_id);
      expect(
        (
          await request(
            `${ordersPath()}/invalid/${operation}`,
            'POST',
            payment,
            1,
          )
        ).status,
      ).toBe(400);
      expect(
        (
          await request(
            `${ordersPath()}/${order.order_id}/${operation}`,
            'POST',
            { payment_method: 'INVALID' },
            1,
          )
        ).status,
      ).toBe(400);
      expect(
        (
          await request(
            `${ordersPath()}/${order.order_id}/${operation}`,
            'POST',
            { ...payment, unexpected: true },
            1,
          )
        ).status,
      ).toBe(400);
      expect(await savedOrder(order.order_id)).toEqual(before);
    },
  );

  it.each([0, 1, 2, 3, -1])(
    'IT-ORD-003 Given session %s When creating an order Then allow shared brand access and require authentication',
    async (user) => {
      expect(
        (await request(ordersPath(), 'POST', orderBody(), user)).status,
      ).toBe(user < 0 ? 401 : 201);
    },
  );

  it('IT-ORD-004 Given a draft When verifying and confirming Then save a queued ticket and private snapshots without inventory changes', async () => {
    await channel();
    const order = await draft('GRABFOOD');
    const before = await savedOrder(order.order_id);
    expect(before.kitchen_tickets_order).toBeNull();
    expect(before.order_items_order[0].recipe_snapshot).toBeNull();
    const verified = await request(
      `${ordersPath()}/${order.order_id}/verify`,
      'POST',
      {},
      1,
    );
    expect(verified.status).toBe(200);
    expect(await json(verified)).toMatchObject({
      valid: true,
      lines: [
        { unit_price: '120', applied_recipe_id: fixture.recipe.recipe_id },
      ],
    });
    expect(await savedOrder(order.order_id)).toEqual(before);
    const confirmed = await request(
      `${ordersPath()}/${order.order_id}/confirm`,
      'POST',
      {},
      1,
    );
    expect(confirmed.status).toBe(200);
    const response = await json(confirmed);
    expect(response.order_code).toBe(before.order_code);
    expect(JSON.stringify(response)).not.toContain(
      'Restricted fixture instructions',
    );
    expect(JSON.stringify(response)).not.toContain('recipe_snapshot');
    const saved = await savedOrder(order.order_id);
    expect(saved.status).toBe('CONFIRMED');
    expect(saved.kitchen_tickets_order).toMatchObject({
      order_code: before.order_code,
      status: 'QUEUED',
      created_by_id: fixture.users[1].user_id,
    });
    expect(saved.kitchen_tickets_order?.ticket_number).toMatch(/^T-\d{3,}$/);
    expect(saved.order_items_order[0].recipe_snapshot).toMatchObject({
      instructions: 'Restricted fixture instructions',
      recipe_components_recipe: [expect.objectContaining({ quantity: '3' })],
    });
    expect(
      saved.order_items_order[0].order_item_modifiers_order_item[0],
    ).toMatchObject({ modifier_name: 'Extra rice' });
    expect(
      saved.order_items_order[0].order_item_modifiers_order_item[0].additional_price.toString(),
    ).toBe('25');
    expect(
      (
        await prisma.inventoryItem.findUniqueOrThrow({
          where: { inventory_item_id: fixture.ingredient.inventory_item_id },
        })
      ).quantity_on_hand.toString(),
    ).toBe('100');
    expect(
      await prisma.stockMovement.count({
        where: { inventory_item_id: fixture.ingredient.inventory_item_id },
      }),
    ).toBe(0);
  });

  it('IT-ORD-005 Given simultaneous confirmations When both finish Then return one persisted ticket', async () => {
    const order = await draft();
    const path = `${ordersPath()}/${order.order_id}/confirm`;
    const responses = await Promise.all([
      request(path, 'POST', payment, 1),
      request(path, 'POST', payment, 1),
    ]);
    expect(responses.map((response) => response.status)).toEqual([200, 200]);
    expect(await json(responses[0])).toEqual(await json(responses[1]));
    expect(
      await prisma.kitchenTicket.count({ where: { order_id: order.order_id } }),
    ).toBe(1);
  });

  it('IT-ORD-006 Given ticket insertion failure after snapshot writes When confirming Then roll back the real transaction', async () => {
    const order = await draft();
    const before = await savedOrder(order.order_id);
    const failingClient = prisma.$extends({
      query: {
        kitchenTicket: {
          create() {
            throw new Error('Injected ticket failure');
          },
        },
      },
    });
    const service = new OrdersService(
      new OrdersRepository(failingClient as unknown as PrismaService),
      new OrderItemsService(new OrderItemsRepository()),
    );
    await expect(
      service.confirm(
        fixture.brand.brand_id,
        order.order_id,
        fixture.users[1].user_id,
        payment as { payment_method: 'CASH'; payment_status: 'UNPAID' },
      ),
    ).rejects.toThrow('Injected ticket failure');
    expect(await savedOrder(order.order_id)).toEqual(before);
    expect(
      await prisma.kitchenTicket.count({ where: { order_id: order.order_id } }),
    ).toBe(0);
  });

  it('IT-ORD-007 Given a price change after verification When confirming and replaying Then snapshot the latest price once', async () => {
    const record = await channel();
    const order = await draft('GRABFOOD');
    const path = `${ordersPath()}/${order.order_id}`;
    expect((await request(`${path}/verify`, 'POST', {}, 1)).status).toBe(200);
    await prisma.menuItemChannel.update({
      where: { menu_item_channel_id: record.menu_item_channel_id },
      data: { price: 150 },
    });
    expect((await request(`${path}/confirm`, 'POST', {}, 1)).status).toBe(200);
    const confirmed = await savedOrder(order.order_id);
    expect(confirmed.order_items_order[0].unit_price.toString()).toBe('150');
    await prisma.menuItemChannel.update({
      where: { menu_item_channel_id: record.menu_item_channel_id },
      data: { price: 200 },
    });
    expect((await request(`${path}/confirm`, 'POST', {}, 1)).status).toBe(200);
    expect(await savedOrder(order.order_id)).toEqual(confirmed);
  });

  it('IT-ORD-008 Given a channel disabled after draft creation When confirming Then preserve the draft without a ticket', async () => {
    const record = await channel();
    const order = await draft('GRABFOOD');
    const before = await savedOrder(order.order_id);
    await prisma.menuItemChannel.update({
      where: { menu_item_channel_id: record.menu_item_channel_id },
      data: { is_available: false },
    });
    expect(
      (
        await request(
          `${ordersPath()}/${order.order_id}/confirm`,
          'POST',
          {},
          1,
        )
      ).status,
    ).toBe(400);
    expect(await savedOrder(order.order_id)).toEqual(before);
  });

  it.each(
    (['GRABFOOD', 'FOODPANDA'] as const).flatMap((order_channel) =>
      (
        ['merchant_store_reference', 'external_order_reference'] as const
      ).flatMap((field) =>
        [undefined, null, '', '   '].map((value) => ({
          order_channel,
          field,
          value,
        })),
      ),
    ),
  )(
    'IT-ORD-009 rejects $order_channel with $field=$value before persistence',
    async ({ order_channel, field, value }) => {
      const response = await request(
        ordersPath(),
        'POST',
        { ...orderBody(order_channel), [field]: value },
        1,
      );
      expect(response.status).toBe(400);
      expect(
        await prisma.order.count({
          where: { brand_id: fixture.brand.brand_id },
        }),
      ).toBe(0);
      expect(
        await prisma.orderDailyCounter.count({
          where: { brand_id: fixture.brand.brand_id },
        }),
      ).toBe(0);
    },
  );

  it.each(
    (['GRABFOOD', 'FOODPANDA'] as const).flatMap((order_channel) =>
      [false, true].map((concurrent) => ({ order_channel, concurrent })),
    ),
  )(
    'IT-ORD-010 blocks normalized $order_channel duplicates with concurrent=$concurrent and returns the saved order',
    async ({ order_channel, concurrent }) => {
      const body = orderBody(order_channel);
      const duplicate = {
        ...body,
        order_id: randomUUID(),
        merchant_store_reference: ` ${body.merchant_store_reference} `,
        external_order_reference: ` ${body.external_order_reference} `,
        notes: 'Different content must not replace the original order',
      };
      const responses = concurrent
        ? await Promise.all([
            request(ordersPath(), 'POST', body, 1),
            request(ordersPath(), 'POST', duplicate, 1),
          ])
        : [
            await request(ordersPath(), 'POST', body, 1),
            await request(ordersPath(), 'POST', duplicate, 1),
          ];
      expect(responses.map((r) => r.status).sort()).toEqual([201, 409]);
      const success = await json(responses.find((r) => r.status === 201)!);
      const conflict = await json(responses.find((r) => r.status === 409)!);
      expect(conflict).toMatchObject({
        statusCode: 409,
        code: 'DUPLICATE_PLATFORM_ORDER',
        existing_order: success,
      });
      expect(JSON.stringify(conflict)).not.toMatch(
        /create_request_hash|recipe_snapshot|Restricted fixture instructions/,
      );
      expect(
        await prisma.order.count({
          where: { brand_id: fixture.brand.brand_id },
        }),
      ).toBe(1);
      expect(
        await prisma.orderItem.count({
          where: { order: { brand_id: fixture.brand.brand_id } },
        }),
      ).toBe(1);
      expect(
        await prisma.orderItemModifier.count({
          where: {
            order_item: { order: { brand_id: fixture.brand.brand_id } },
          },
        }),
      ).toBe(1);
      const next = await request(ordersPath(), 'POST', orderBody(), 1);
      expect(next.status).toBe(201);
      expect(await json(next)).toMatchObject({ order_number: 2 });
    },
  );

  it.each([
    { name: 'channel', change: { order_channel: 'FOODPANDA' } },
    { name: 'store', change: { merchant_store_reference: 'another-store' } },
    { name: 'store case', change: { merchant_store_reference: 'TEST-STORE' } },
    {
      name: 'external reference',
      change: { external_order_reference: 'other' },
    },
    {
      name: 'reference case',
      change: { external_order_reference: 'PLATFORM-1' },
    },
  ] as const)(
    'IT-ORD-011 permits platform lookalikes differing in $name',
    async ({ change }) => {
      const body = {
        ...orderBody('GRABFOOD'),
        external_order_reference: 'platform-1',
      };
      const responses = await Promise.all(
        [body, { ...body, ...change, order_id: randomUUID() }].map((payload) =>
          request(
            ordersPath(),
            'POST',
            {
              ...payload,
              merchant_store_reference: `${fixture.brand.brand_id}-${payload.merchant_store_reference}`,
            },
            1,
          ),
        ),
      );
      expect(responses.map((r) => r.status)).toEqual([201, 201]);
      expect(
        await prisma.order.count({
          where: { brand_id: fixture.brand.brand_id },
        }),
      ).toBe(2);
    },
  );

  it.each(['DINE_IN', 'TAKEAWAY', 'GRABFOOD', 'FOODPANDA'] as const)(
    'IT-ORD-012 recovers concurrent and committed %s creates with the same UUID',
    async (channel) => {
      const body = orderBody(channel);
      const responses = await Promise.all([
        request(ordersPath(), 'POST', body, 1),
        request(ordersPath(), 'POST', body, 1),
        request(ordersPath(), 'POST', body, 1),
      ]);
      expect(responses.map((r) => r.status)).toEqual([201, 201, 201]);
      const orders = await Promise.all(responses.map(json));
      expect(orders[1]).toEqual(orders[0]);
      expect(orders[2]).toEqual(orders[0]);
      const confirmed = await request(
        `${ordersPath()}/${body.order_id}/confirm`,
        'POST',
        channel === 'DINE_IN' || channel === 'TAKEAWAY' ? payment : {},
        1,
      );
      expect(confirmed.status).toBe(200);
      const saved = await json(confirmed);
      // Simulate recovery after the original committed response was lost, even
      // when the current catalog would no longer accept a new order.
      await prisma.menuItem.update({
        where: { menu_item_id: fixture.item.menu_item_id },
        data: { is_available: false },
      });
      const replay = await request(ordersPath(), 'POST', body, 0);
      expect(replay.status).toBe(201);
      expect(await json(replay)).toEqual(saved);
      if (channel === 'GRABFOOD' || channel === 'FOODPANDA') {
        const duplicate = await request(
          ordersPath(),
          'POST',
          { ...body, order_id: randomUUID() },
          1,
        );
        expect(duplicate.status).toBe(409);
        expect(await json(duplicate)).toMatchObject({ existing_order: saved });
      }
      expect(
        await prisma.order.count({
          where: { brand_id: fixture.brand.brand_id },
        }),
      ).toBe(1);
      expect(
        await prisma.orderItem.count({ where: { order_id: body.order_id } }),
      ).toBe(1);
      expect(
        await prisma.kitchenTicket.count({
          where: { order_id: body.order_id },
        }),
      ).toBe(1);
      expect(
        await prisma.orderDailyCounter.findFirstOrThrow({
          where: { brand_id: fixture.brand.brand_id },
        }),
      ).toMatchObject({ last_number: 1 });
    },
  );

  it.each([false, true])(
    'IT-ORD-013 rejects changed content for the same UUID with concurrent=%s',
    async (concurrent) => {
      const body = orderBody();
      const changed = { ...body, notes: 'Changed request' };
      const responses = concurrent
        ? await Promise.all([
            request(ordersPath(), 'POST', body, 1),
            request(ordersPath(), 'POST', changed, 1),
          ])
        : [
            await request(ordersPath(), 'POST', body, 1),
            await request(ordersPath(), 'POST', changed, 1),
          ];
      expect(responses.map((r) => r.status).sort()).toEqual([201, 409]);
      const success = await json(responses.find((r) => r.status === 201)!);
      expect(
        await json(responses.find((r) => r.status === 409)!),
      ).toMatchObject({
        code: 'ORDER_ID_CONFLICT',
      });
      expect(await savedOrder(body.order_id)).toMatchObject({
        notes: success.notes,
      });
      expect(
        await prisma.order.count({
          where: { brand_id: fixture.brand.brand_id },
        }),
      ).toBe(1);
    },
  );

  it('IT-ORD-014 never exposes another brand through platform or UUID conflicts', async () => {
    const body = await draft('GRABFOOD');
    const before = await savedOrder(body.order_id);
    const otherPath = `/brands/${fixture.otherBrand.brand_id}/orders`;
    const duplicate = await request(
      otherPath,
      'POST',
      { ...body, order_id: randomUUID() },
      3,
    );
    expect(duplicate.status).toBe(409);
    const conflict = await json(duplicate);
    expect(conflict).toEqual({
      statusCode: 409,
      error: 'Conflict',
      code: 'DUPLICATE_PLATFORM_ORDER',
      message: 'Platform order already exists.',
      existing_order: null,
    });
    const reusedId = await request(otherPath, 'POST', body, 3);
    expect(reusedId.status).toBe(409);
    expect(await json(reusedId)).toEqual({
      statusCode: 409,
      error: 'Conflict',
      code: 'ORDER_ID_CONFLICT',
      message: 'Order ID was already used for a different request.',
    });
    // Managers can replay orders across brands; authentication still applies.
    const replay = await request(ordersPath(), 'POST', body, 3);
    expect(replay.status).toBe(201);
    expect(await json(replay)).toMatchObject({
      order_id: body.order_id,
      brand_id: fixture.brand.brand_id,
    });
    expect((await request(ordersPath(), 'POST', body, -1)).status).toBe(401);
    expect(await savedOrder(body.order_id)).toEqual(before);
    expect(
      await prisma.order.count({
        where: { brand_id: fixture.otherBrand.brand_id },
      }),
    ).toBe(0);
  });

  it('IT-ORD-015 concurrent conflicting confirmations preserve the winning payment and unique ticket numbers', async () => {
    const first = await draft();
    const second = await draft();
    const confirmPath = `${ordersPath()}/${first.order_id}/confirm`;
    const responses = await Promise.all([
      request(confirmPath, 'POST', payment, 1),
      request(
        confirmPath,
        'POST',
        {
          payment_method: 'CARD',
          payment_status: 'PAID',
          payment_reference: 'p1',
        },
        0,
      ),
      request(`${ordersPath()}/${second.order_id}/confirm`, 'POST', payment, 1),
    ]);
    expect(responses.map((r) => r.status)).toEqual([200, 200, 200]);
    const orders = await Promise.all(responses.map(json));
    expect(orders[0]).toEqual(orders[1]);
    const saved = await savedOrder(first.order_id);
    expect(saved.payment_method).toBe(orders[0].payment_method);
    expect(saved.payment_status).toBe(orders[0].payment_status);
    expect(saved.payment_reference).toBe(orders[0].payment_reference);
    const tickets = await prisma.kitchenTicket.findMany({
      where: { order: { brand_id: fixture.brand.brand_id } },
    });
    expect(tickets).toHaveLength(2);
    expect(new Set(tickets.map((t) => t.ticket_number)).size).toBe(2);
    expect(new Set(tickets.map((t) => t.order_id)).size).toBe(2);
  });

  it('IT-ORD-016 rolls back inserted order lines and modifiers, then safely retries the same UUID', async () => {
    const body = orderBody();
    const failingClient = prisma.$extends({
      query: {
        order: {
          async create({ args, query }) {
            await query(args);
            throw new Error('Injected failure after order insertion');
          },
        },
      },
    });
    const service = new OrdersService(
      new OrdersRepository(failingClient as unknown as PrismaService),
      new OrderItemsService(new OrderItemsRepository()),
    );
    await expect(
      service.create(fixture.brand.brand_id, fixture.users[1].user_id, body),
    ).rejects.toThrow('Injected failure after order insertion');
    expect(
      await prisma.order.count({ where: { order_id: body.order_id } }),
    ).toBe(0);
    expect(
      await prisma.orderItem.count({ where: { order_id: body.order_id } }),
    ).toBe(0);
    expect(
      await prisma.orderItemModifier.count({
        where: { modifier_id: fixture.modifier.modifier_id },
      }),
    ).toBe(0);
    expect(
      await prisma.orderDailyCounter.count({
        where: { brand_id: fixture.brand.brand_id },
      }),
    ).toBe(0);
    const recovered = await request(ordersPath(), 'POST', body, 1);
    expect(recovered.status).toBe(201);
    expect(await json(recovered)).toMatchObject({ order_number: 1 });
  });

  it('IT-ORD-017 rolls back a ticket inserted before confirmation fails, then recovers with one ticket', async () => {
    const body = await draft();
    const before = await savedOrder(body.order_id);
    const failingClient = prisma.$extends({
      query: {
        order: {
          update() {
            throw new Error('Injected failure after ticket insertion');
          },
        },
      },
    });
    const service = new OrdersService(
      new OrdersRepository(failingClient as unknown as PrismaService),
      new OrderItemsService(new OrderItemsRepository()),
    );
    await expect(
      service.confirm(
        fixture.brand.brand_id,
        body.order_id,
        fixture.users[1].user_id,
        payment as { payment_method: 'CASH'; payment_status: 'UNPAID' },
      ),
    ).rejects.toThrow('Injected failure after ticket insertion');
    expect(await savedOrder(body.order_id)).toEqual(before);
    expect(
      await prisma.kitchenTicket.count({ where: { order_id: body.order_id } }),
    ).toBe(0);
    const path = `${ordersPath()}/${body.order_id}/confirm`;
    const recovered = await request(path, 'POST', payment, 1);
    expect(recovered.status).toBe(200);
    const replay = await request(path, 'POST', {}, 1);
    expect(replay.status).toBe(200);
    expect(await json(replay)).toEqual(await json(recovered));
    expect(
      await prisma.kitchenTicket.count({ where: { order_id: body.order_id } }),
    ).toBe(1);
  });

  it('IT-ORD-021: assigns consecutive daily codes across channels and keeps cancelled draft numbers', async () => {
    const first = await draft();
    const saved = await savedOrder(first.order_id);
    expect(saved.order_code).toBe(`${fixture.brand.code.trim()}-00001`);
    expect(saved.order_number).toBe(1);
    const [{ order_date }] = await prisma.$queryRaw<
      { order_date: Date }[]
    >`SELECT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila')::date AS order_date`;
    expect(saved.order_date).toEqual(order_date);
    await prisma.order.update({
      where: { order_id: first.order_id },
      data: { status: 'CANCELLED' },
    });
    const second = await request(ordersPath(), 'POST', orderBody('DINE_IN'), 1);
    expect(second.status).toBe(201);
    expect(await json(second)).toMatchObject({
      order_code: `${fixture.brand.code.trim()}-00002`,
      order_number: 2,
    });
    const platform = await request(
      ordersPath(),
      'POST',
      orderBody('GRABFOOD'),
      1,
    );
    expect(platform.status).toBe(201);
    expect(await json(platform)).toMatchObject({
      order_code: `${fixture.brand.code.trim()}-00003`,
      order_number: 3,
    });
  });

  it('IT-ORD-022: starts a separate sequence for another brand', async () => {
    await draft();
    const recipe = await prisma.recipe.create({
      data: {
        brand_id: fixture.otherBrand.brand_id,
        code: randomUUID(),
        name: 'Other brand assembly',
        type: 'MENU_ASSEMBLY',
      },
    });
    const item = await prisma.menuItem.create({
      data: {
        brand_id: fixture.otherBrand.brand_id,
        recipe_id: recipe.recipe_id,
        code: randomUUID(),
        name: 'Other brand meal',
        img_url: 'uploads/fixture.png',
        base_price: 50,
      },
    });
    const response = await request(
      `/brands/${fixture.otherBrand.brand_id}/orders`,
      'POST',
      {
        ...orderBody(),
        lines: [{ menu_item_id: item.menu_item_id, quantity: 1 }],
      },
      2,
    );
    expect(response.status).toBe(201);
    expect(await json(response)).toMatchObject({
      order_code: `${fixture.otherBrand.code.trim()}-00001`,
      order_number: 1,
    });
  });

  it('IT-ORD-023: assigns different codes to simultaneous creates and preserves them on replay', async () => {
    const bodies = Array.from({ length: 4 }, () => orderBody());
    const responses = await Promise.all(
      bodies.map((body) => request(ordersPath(), 'POST', body, 1)),
    );
    expect(responses.map((response) => response.status)).toEqual([
      201, 201, 201, 201,
    ]);
    const orders = await Promise.all(responses.map(json));
    expect(orders.map((order) => order.order_number).sort()).toEqual([
      1, 2, 3, 4,
    ]);
    expect(new Set(orders.map((order) => order.order_code)).size).toBe(4);
    const replay = await request(ordersPath(), 'POST', bodies[0], 1);
    expect(replay.status).toBe(201);
    expect(await json(replay)).toEqual(orders[0]);
    const next = await request(ordersPath(), 'POST', orderBody(), 1);
    expect(next.status).toBe(201);
    expect(await json(next)).toMatchObject({ order_number: 5 });
  });

  it('IT-ORD-024: allocates one number for simultaneous creates with the same UUID', async () => {
    const body = orderBody();
    const responses = await Promise.all([
      request(ordersPath(), 'POST', body, 1),
      request(ordersPath(), 'POST', body, 1),
    ]);
    expect(responses.map((response) => response.status)).toEqual([201, 201]);
    expect(await json(responses[0])).toEqual(await json(responses[1]));
    const next = await request(ordersPath(), 'POST', orderBody(), 1);
    expect(next.status).toBe(201);
    expect(await json(next)).toMatchObject({ order_number: 2 });
  });

  it('IT-ORD-025: rolls back the allocated number if order insertion fails', async () => {
    const body = orderBody();
    const failingClient = prisma.$extends({
      query: {
        order: {
          create() {
            throw new Error('Injected order failure');
          },
        },
      },
    });
    const service = new OrdersService(
      new OrdersRepository(failingClient as unknown as PrismaService),
      new OrderItemsService(new OrderItemsRepository()),
    );
    await expect(
      service.create(fixture.brand.brand_id, fixture.users[1].user_id, body),
    ).rejects.toThrow('Injected order failure');
    expect(
      await prisma.orderDailyCounter.count({
        where: { brand_id: fixture.brand.brand_id },
      }),
    ).toBe(0);
    const response = await request(ordersPath(), 'POST', body, 1);
    expect(response.status).toBe(201);
    expect(await json(response)).toMatchObject({ order_number: 1 });
  });

  it('IT-ORD-026: continues a seeded daily counter and snapshots subsequent brand code changes', async () => {
    const [{ order_date }] = await prisma.$queryRaw<
      { order_date: Date }[]
    >`SELECT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila')::date AS order_date`;
    await prisma.orderDailyCounter.create({
      data: { brand_id: fixture.brand.brand_id, order_date, last_number: 17 },
    });
    const body = orderBody();
    const response = await request(ordersPath(), 'POST', body, 1);
    expect(response.status).toBe(201);
    const original = await json(response);
    expect(original).toMatchObject({
      order_code: `${fixture.brand.code.trim()}-00018`,
      order_number: 18,
    });
    let code: string;
    do {
      code = randomUUID().slice(0, 4).toUpperCase();
    } while (await prisma.brand.findUnique({ where: { code } }));
    await prisma.brand.update({
      where: { brand_id: fixture.brand.brand_id },
      data: { code },
    });
    const replay = await request(ordersPath(), 'POST', body, 1);
    expect(replay.status).toBe(201);
    expect(await json(replay)).toEqual(original);
    const next = await request(ordersPath(), 'POST', orderBody(), 1);
    expect(next.status).toBe(201);
    expect(await json(next)).toMatchObject({
      order_code: `${code}-00019`,
      order_number: 19,
    });
  });
});

describe('Draft cancellation HTTP API', () => {
  const brandId = '11111111-1111-4111-8111-111111111111';
  const orderId = '22222222-2222-4222-8222-222222222222';
  const actorId = '33333333-3333-4333-8333-333333333333';
  const auth = { validateSession: jest.fn() };
  const prisma = { order: { findUnique: jest.fn() } };
  const service = { cancelDraft: jest.fn() };
  const cancelMethod = service.cancelDraft;
  let app: INestApplication;
  let url: string;

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [OrdersController],
      providers: [
        { provide: OrdersService, useValue: service },
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
    url = await app.getUrl();
  });

  beforeEach(() => {
    jest.resetAllMocks();
    auth.validateSession.mockResolvedValue({
      user: {
        user_id: actorId,
        brand_id: brandId,
        role: UserRole.CASHIER_STAFF,
      },
    });
    prisma.order.findUnique.mockResolvedValue({ brand_id: brandId });
    cancelMethod.mockResolvedValue({
      order_id: orderId,
      status: 'CANCELLED',
    });
  });

  afterAll(async () => app?.close());

  function cancel(
    body: unknown = { cancellation_reason: 'Customer request' },
    token = true,
    brand = brandId,
    order = orderId,
  ) {
    return fetch(`${url}/api/brands/${brand}/orders/${order}/cancel`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: 'Bearer test-session' } : {}),
      },
      body: JSON.stringify(body),
    });
  }

  it.each([UserRole.CASHIER_STAFF, UserRole.MANAGER, UserRole.SUPERADMIN])(
    'IT-ORD-029: allows %s and takes the actor from the session',
    async (role) => {
      auth.validateSession.mockResolvedValue({
        user: {
          user_id: actorId,
          role,
          brand_id: role === UserRole.SUPERADMIN ? null : brandId,
        },
      });
      const response = await cancel();
      expect(response.status).toBe(200);
      expect(await response.json()).toMatchObject({
        order_id: orderId,
        status: 'CANCELLED',
      });
      expect(cancelMethod).toHaveBeenCalledWith(brandId, orderId, actorId, {
        cancellation_reason: 'Customer request',
      });
    },
  );

  it.each([
    {},
    { cancellation_reason: '' },
    { cancellation_reason: '   ' },
    { cancellation_reason: null },
    { cancellation_reason: 123 },
    { cancellation_reason: 'x'.repeat(1001) },
    { cancellation_reason: 'Customer request', cancelled_by_id: actorId },
  ])('IT-ORD-030: rejects invalid or extra body fields: %p', async (body) => {
    expect((await cancel(body)).status).toBe(400);
    expect(cancelMethod).not.toHaveBeenCalled();
  });

  it('IT-ORD-031: requires authentication', async () => {
    expect((await cancel(undefined, false)).status).toBe(401);
    expect(cancelMethod).not.toHaveBeenCalled();
  });

  it.each(
    Object.values(UserRole).filter(
      (role) =>
        !(
          [
            UserRole.CASHIER_STAFF,
            UserRole.MANAGER,
            UserRole.SUPERADMIN,
          ] as UserRole[]
        ).includes(role),
    ),
  )('IT-ORD-032: rejects other role %s', async (role) => {
    auth.validateSession.mockResolvedValue({
      user: {
        user_id: actorId,
        brand_id: brandId,
        role,
      },
    });
    expect((await cancel()).status).toBe(403);
    expect(cancelMethod).not.toHaveBeenCalled();
  });

  it('IT-ORD-033: returns 404 for a missing order', async () => {
    cancelMethod.mockRejectedValueOnce(new NotFoundException());
    expect((await cancel()).status).toBe(404);
    expect(cancelMethod).toHaveBeenCalled();
  });

  it.each([
    ['invalid', orderId],
    [brandId, 'invalid'],
  ])(
    'IT-ORD-034: rejects malformed brand or order IDs %s / %s',
    async (brand, order) => {
      expect((await cancel(undefined, true, brand, order)).status).toBe(400);
      expect(cancelMethod).not.toHaveBeenCalled();
    },
  );
});
