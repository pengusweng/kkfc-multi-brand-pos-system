import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { Prisma, UserRole } from '@prisma/client';
import {
  auditPipelineProviders,
  createAuditSpy,
} from '../../../shared/testing/audit.testing';
import { AssetsService } from '../../assets/assets.service';
import { AuthService } from '../../auth/auth.service';
import { BrandsController } from '../brands.controller';
import { BrandsService } from '../brands.service';

const actorId = '11111111-1111-4111-8111-111111111111';
const brandId = '22222222-2222-4222-8222-222222222222';
const newBrandId = '33333333-3333-4333-8333-333333333333';

const prismaError = (code: string) =>
  new Prisma.PrismaClientKnownRequestError('Prisma error', {
    code,
    clientVersion: 'test',
  });

describe('Brands audit logging', () => {
  let app: INestApplication;
  let url: string;
  let role: UserRole;
  const audit = createAuditSpy();
  const brands = {
    create: jest.fn(),
    findOne: jest.fn(),
    findAll: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
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
      controllers: [BrandsController],
      providers: [
        { provide: BrandsService, useValue: brands },
        { provide: AssetsService, useValue: { upload: jest.fn() } },
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
    url = `${await app.getUrl()}/api/brands`;
  });

  afterAll(async () => app.close());

  beforeEach(() => {
    role = UserRole.SUPERADMIN;
    audit.create.mockClear().mockResolvedValue({});
    for (const mock of Object.values(brands)) mock.mockReset();
  });

  function call(method: string, path = '', body?: unknown) {
    return fetch(`${url}${path}`, {
      method,
      headers: {
        Authorization: 'Bearer token',
        'Content-Type': 'application/json',
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
  }

  it('IT-BRND-031: Given a superadmin, When a brand is created, updated and deactivated, Then audit each against the brand', async () => {
    brands.create.mockResolvedValue({ brand_id: newBrandId });
    brands.update.mockResolvedValue({ brand_id: brandId });
    brands.delete.mockResolvedValue({ brand_id: brandId });

    const statuses = [
      (await call('POST', '', { name: 'Gamcheon', code: 'GC2' })).status,
      (await call('PATCH', `/${brandId}`, { name: 'Gamcheon Two' })).status,
      (await call('DELETE', `/${brandId}`)).status,
    ];

    expect(statuses).toEqual([201, 200, 200]);
    expect(audit.rows()).toEqual([
      expect.objectContaining({
        actor_id: actorId,
        action: 'BRAND_CREATED',
        entity_type: 'brands',
        entity_id: newBrandId,
        outcome: 'SUCCESS',
      }),
      expect.objectContaining({
        action: 'BRAND_UPDATED',
        entity_id: brandId,
        outcome: 'SUCCESS',
      }),
      expect.objectContaining({
        action: 'BRAND_DEACTIVATED',
        entity_id: brandId,
        outcome: 'SUCCESS',
      }),
    ]);
  });

  it('IT-BRND-032: Given a duplicate code and an already inactive brand, When they are saved or deactivated, Then audit the conflict but not the missing brand', async () => {
    brands.create.mockRejectedValue(prismaError('P2002'));
    brands.delete.mockRejectedValue(prismaError('P2025'));

    const duplicate = await call('POST', '', { name: 'Gamcheon', code: 'GC' });
    const inactive = await call('DELETE', `/${brandId}`);

    expect([duplicate.status, inactive.status]).toEqual([409, 404]);
    expect(audit.rows()).toEqual([
      expect.objectContaining({
        action: 'BRAND_CREATED',
        entity_id: null,
        outcome: 'FAILED',
        reason: 'DUPLICATE_RESOURCE',
      }),
    ]);
  });

  it('IT-BRND-033: Given a manager and routine brand reads, When brands are read and a brand is created, Then only the role denial is audited', async () => {
    brands.findAll.mockResolvedValue({ data: [], meta: {} });
    brands.findOne.mockResolvedValue({ brand_id: brandId });

    role = UserRole.MANAGER;
    const list = await call('GET');
    const view = await call('GET', `/${brandId}`);
    const create = await call('POST', '', { name: 'Gamcheon', code: 'GC2' });

    expect([list.status, view.status, create.status]).toEqual([200, 200, 403]);
    expect(brands.create).not.toHaveBeenCalled();
    expect(audit.rows()).toEqual([
      expect.objectContaining({
        actor_id: actorId,
        action: 'BRAND_CREATED',
        outcome: 'DENIED',
        reason: 'ACCESS_DENIED',
      }),
    ]);
  });
});
