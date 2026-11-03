import {
  ConflictException,
  ForbiddenException,
  INestApplication,
  NotFoundException,
  ValidationPipe,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { QcRejectionReason, UserRole } from '@prisma/client';
import { AuthService } from '../../../auth/auth.service';
import { AssetsService } from '../../../assets/assets.service';
import { KitchenFulfillmentController } from '../kitchen-fulfillment.controller';
import { KitchenFulfillmentService } from '../kitchen-fulfillment.service';

describe('Kitchen fulfillment HTTP endpoints', () => {
  const id = '00000000-0000-4000-8000-000000000001';
  const actorId = '00000000-0000-4000-8000-000000000002';
  const brandId = '00000000-0000-4000-8000-000000000003';
  const rejection = {
    order_item_id: id,
    portion_number: 1,
    rejection_reason: Object.values(QcRejectionReason)[0],
    description: 'The portion needs rework.',
  };
  const rejectionBody = { rejections: [rejection] };
  const handoverBody = { img_keys: ['uploads/handoff.png'] };
  const cancelBody = {
    cancellation_reason: 'Customer requested cancellation.',
  };
  const cancelPath = `/brands/${brandId}/orders/${id}/cancel`;
  const result = { success: true };
  const service = {
    acknowledge: jest.fn(),
    prepare: jest.fn(),
    forChecking: jest.fn(),
    check: jest.fn(),
    passQCAttempt: jest.fn(),
    rejectQcAttempt: jest.fn(),
    handOver: jest.fn(),
    cancel: jest.fn(),
  };
  const routes = [
    { path: `/${id}/acknowledge`, handler: 'acknowledge', args: [id] },
    { path: `/${id}/prepare`, handler: 'prepare', args: [id, actorId] },
    {
      path: `/${id}/for-checking`,
      handler: 'forChecking',
      args: [id, actorId],
    },
    { path: `/${id}/check`, handler: 'check', args: [id, actorId] },
    {
      path: `/qc-attempts/${id}/pass`,
      handler: 'passQCAttempt',
      args: [id, actorId],
    },
    {
      path: `/qc-attempts/${id}/reject`,
      handler: 'rejectQcAttempt',
      body: rejectionBody,
      args: [id, actorId, rejectionBody],
    },
    {
      path: `/${id}/hand-over`,
      handler: 'handOver',
      body: handoverBody,
      args: [id, actorId, handoverBody],
    },
    {
      path: cancelPath,
      handler: 'cancel',
      body: cancelBody,
      args: [brandId, id, actorId, cancelBody],
    },
  ] as const;
  const auth = { validateSession: jest.fn() };
  const kitchenRoles: UserRole[] = [
    UserRole.SUPERADMIN,
    UserRole.MANAGER,
    UserRole.SUPERVISOR,
    UserRole.KITCHEN_STAFF,
    UserRole.KITCHEN_HEAD,
  ];
  const checkerRoles: UserRole[] = [
    UserRole.SUPERADMIN,
    UserRole.MANAGER,
    UserRole.SUPERVISOR,
    UserRole.KITCHEN_HEAD,
  ];
  const assets = { upload: jest.fn() };
  let app: INestApplication;
  let url: string;

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [KitchenFulfillmentController],
      providers: [
        { provide: KitchenFulfillmentService, useValue: service },
        { provide: AuthService, useValue: auth },
        { provide: AssetsService, useValue: assets },
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
    url = `${await app.getUrl()}/api/kitchen-fulfillment`;
  });

  beforeEach(() => {
    jest.resetAllMocks();
    auth.validateSession.mockImplementation((role: UserRole) =>
      Promise.resolve({ user: { user_id: actorId, role } }),
    );
    for (const handler of Object.values(service))
      handler.mockResolvedValue(result);
  });

  afterAll(async () => app?.close());

  function request(
    path: string,
    body?: unknown,
    authorization: string | null = `Bearer ${UserRole.KITCHEN_HEAD}`,
  ) {
    return fetch(`${url}${path}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...(authorization === null ? {} : { Authorization: authorization }),
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
  }

  describe.each(routes)('POST $path', (route) => {
    const body = 'body' in route ? route.body : undefined;
    const roles = [
      'check',
      'passQCAttempt',
      'rejectQcAttempt',
      'cancel',
    ].includes(route.handler)
      ? checkerRoles
      : kitchenRoles;

    it.each(roles)(
      'IT-KFUL-005: accepts permitted role %s and forwards the session actor',
      async (role) => {
        const response = await request(route.path, body, `Bearer ${role}`);
        expect(response.status).toBe(200);
        expect(await response.json()).toEqual(result);
        expect(auth.validateSession).toHaveBeenCalledWith(role);
        expect(service[route.handler]).toHaveBeenCalledTimes(1);
        expect(service[route.handler]).toHaveBeenCalledWith(...route.args);
      },
    );

    it.each(Object.values(UserRole).filter((role) => !roles.includes(role)))(
      'IT-KFUL-018: denies role %s before calling the service',
      async (role) => {
        const response = await request(route.path, body, `Bearer ${role}`);
        expect(response.status).toBe(403);
        expect(service[route.handler]).not.toHaveBeenCalled();
      },
    );

    it('IT-KFUL-006: requires authentication before calling the service', async () => {
      expect((await request(route.path, body, null)).status).toBe(401);
      expect(auth.validateSession).not.toHaveBeenCalled();
      expect(service[route.handler]).not.toHaveBeenCalled();
    });

    it('IT-KFUL-007: rejects invalid or expired sessions before calling the service', async () => {
      auth.validateSession.mockRejectedValue(new NotFoundException());
      const response = await request(route.path, body);
      expect(response.status).toBe(401);
      expect(await response.json()).toMatchObject({ code: 'INVALID_SESSION' });
      expect(service[route.handler]).not.toHaveBeenCalled();
    });

    it('IT-KFUL-008: rejects a malformed ticket attempt or order UUID before calling the service', async () => {
      expect(
        (await request(route.path.replace(id, 'invalid'), body)).status,
      ).toBe(400);
      expect(service[route.handler]).not.toHaveBeenCalled();
    });

    it.each([
      new NotFoundException(),
      new ForbiddenException(),
      new ConflictException(),
    ])('IT-KFUL-009: preserves service failure %p', async (error) => {
      service[route.handler].mockRejectedValue(error);
      expect((await request(route.path, body)).status).toBe(error.getStatus());
    });
  });

  it.each([
    undefined,
    {},
    { rejections: [] },
    { rejections: null },
    { rejections: 'invalid' },
    { rejections: [{ ...rejection, order_item_id: 'invalid' }] },
    { rejections: [{ ...rejection, portion_number: 0 }] },
    { rejections: [{ ...rejection, portion_number: 1.5 }] },
    { rejections: [{ ...rejection, rejection_reason: 'invalid' }] },
    { rejections: [{ ...rejection, description: '   ' }] },
    { rejections: [{ ...rejection, caller_id: actorId }] },
    { ...rejectionBody, caller_id: actorId },
  ])(
    'IT-KFUL-010: rejects invalid or extra QC rejection fields %p',
    async (body) => {
      expect((await request(`/qc-attempts/${id}/reject`, body)).status).toBe(
        400,
      );
      expect(service.rejectQcAttempt).not.toHaveBeenCalled();
    },
  );

  it.each([
    { img_keys: [] },
    { img_keys: null },
    { img_keys: '' },
    { img_keys: [''] },
    { img_keys: ['   '] },
    { img_keys: [123] },
    { img_keys: ['x'.repeat(2049)] },
    { ...handoverBody, actor_id: actorId },
  ])(
    'IT-KFUL-011: rejects invalid or extra handover image fields %p',
    async (body) => {
      expect((await request(`/${id}/hand-over`, body)).status).toBe(400);
      expect(service.handOver).not.toHaveBeenCalled();
    },
  );

  it.each([undefined, {}])(
    'IT-KFUL-012: permits handover without images and leaves delivery requirements to the service (%p)',
    async (body) => {
      expect((await request(`/${id}/hand-over`, body)).status).toBe(200);
      expect(service.handOver).toHaveBeenCalledWith(id, actorId, undefined);
    },
  );

  it.each([
    {},
    { cancellation_reason: '' },
    { cancellation_reason: '   ' },
    { cancellation_reason: null },
    { cancellation_reason: 123 },
    { cancellation_reason: 'x'.repeat(1001) },
    { ...cancelBody, cancelled_by_id: actorId },
  ])(
    'IT-KFUL-013: rejects invalid or extra cancellation fields %p',
    async (body) => {
      expect((await request(cancelPath, body)).status).toBe(400);
      expect(service.cancel).not.toHaveBeenCalled();
    },
  );

  it('IT-KFUL-014: rejects a malformed cancellation brand UUID', async () => {
    expect(
      (await request(cancelPath.replace(brandId, 'invalid'), cancelBody))
        .status,
    ).toBe(400);
    expect(service.cancel).not.toHaveBeenCalled();
  });

  it('IT-KFUL-016: uploads handover files for the session actor and forwards their keys', async () => {
    assets.upload
      .mockResolvedValueOnce({ key: 'uploads/one.png' })
      .mockResolvedValueOnce({ key: 'uploads/two.png' });
    const form = new FormData();
    form.append('files', new Blob(['one'], { type: 'image/png' }), 'one.png');
    form.append('files', new Blob(['two'], { type: 'image/png' }), 'two.png');
    const response = await fetch(`${url}/${id}/hand-over`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${UserRole.KITCHEN_STAFF}` },
      body: form,
    });
    expect(response.status).toBe(200);
    expect(assets.upload).toHaveBeenCalledTimes(2);
    expect(assets.upload).toHaveBeenCalledWith(
      actorId,
      expect.objectContaining({ originalname: 'one.png' }),
    );
    expect(service.handOver).toHaveBeenCalledWith(id, actorId, {
      img_keys: ['uploads/one.png', 'uploads/two.png'],
    });
  });

  it('IT-KFUL-017: rejects more than five uploaded files before uploading', async () => {
    const form = new FormData();
    for (let i = 0; i < 6; i++)
      form.append(
        'files',
        new Blob(['image'], { type: 'image/png' }),
        `${i}.png`,
      );
    const response = await fetch(`${url}/${id}/hand-over`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${UserRole.KITCHEN_STAFF}` },
      body: form,
    });
    expect(response.status).toBe(400);
    expect(await response.json()).toMatchObject({ message: 'Too many files' });
    expect(assets.upload).not.toHaveBeenCalled();
    expect(service.handOver).not.toHaveBeenCalled();
  });
});
