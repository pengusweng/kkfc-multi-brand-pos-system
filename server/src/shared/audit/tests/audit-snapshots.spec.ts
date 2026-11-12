import { ConflictException, ExecutionContext, Logger } from '@nestjs/common';
import { AuditOutcome, Prisma } from '@prisma/client';
import { defer, firstValueFrom, of, throwError } from 'rxjs';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditRecorder } from '../audit-recorder.service';
import {
  changedFields,
  FORBIDDEN_SNAPSHOT_FIELDS,
  SNAPSHOT_CONFIGS,
  toSnapshotJson,
} from '../audit-snapshots';
import {
  Audit,
  AuditableRequest,
  AuditOptions,
  fromParam,
  fromResult,
} from '../audit.decorator';
import { AuditInterceptor } from '../audit.interceptor';

const actorId = '11111111-1111-4111-8111-111111111111';
const itemId = '22222222-2222-4222-8222-222222222222';

/** Generated column enums, e.g. Prisma.MenuItemScalarFieldEnum. */
const columnsOf = (model: string) =>
  Object.values(
    (Prisma as unknown as Record<string, Record<string, string>>)[
      `${model[0].toUpperCase()}${model.slice(1)}ScalarFieldEnum`
    ],
  );

function setup() {
  const create = jest.fn().mockResolvedValue({});
  const findUnique = jest.fn().mockResolvedValue(null);
  const prisma = new Proxy(
    {},
    {
      get: (_target, model) =>
        model === 'auditLog' ? { create } : { findUnique },
    },
  ) as PrismaService;
  return { create, findUnique, recorder: new AuditRecorder(prisma) };
}

function request(audit: AuditOptions, params: Record<string, string> = {}) {
  return {
    headers: {},
    params,
    session: { user: { user_id: actorId } },
    audit,
    auditRequestId: 'req-1',
  } as unknown as AuditableRequest;
}

const httpContext = (req: unknown) =>
  ({
    getType: () => 'http',
    switchToHttp: () => ({ getRequest: () => req }),
  }) as unknown as ExecutionContext;

const updateItem: AuditOptions = {
  action: 'MENU_ITEM_UPDATED',
  entity: 'menu_items',
  id: fromParam('id'),
  snapshot: 'update',
};

describe('Audit snapshots', () => {
  let errorLog: jest.SpyInstance;

  beforeEach(() => {
    errorLog = jest.spyOn(Logger.prototype, 'error').mockImplementation();
  });

  afterEach(() => jest.restoreAllMocks());

  it('UT-AUDIT-018: Given database values, When snapshots are serialized and compared, Then store JSON values and only the changed fields', () => {
    const at = new Date('2026-11-12T00:00:00.000Z');
    const before = toSnapshotJson({
      base_price: new Prisma.Decimal('150.00'),
      name: 'Kimchi Fried Rice',
      is_available: true,
      description: null,
      modified_at: at,
    });
    const after = { ...before, base_price: '165', is_available: false };

    expect(before).toEqual({
      base_price: '150',
      name: 'Kimchi Fried Rice',
      is_available: true,
      description: null,
      modified_at: '2026-11-12T00:00:00.000Z',
    });
    expect(changedFields(before, after)).toEqual({
      before: { base_price: '150', is_available: true },
      after: { base_price: '165', is_available: false },
    });
    expect(changedFields(before, { ...before })).toEqual({
      before: null,
      after: null,
    });
    expect(changedFields(null, after)).toEqual({ before: null, after });
  });

  it('UT-AUDIT-019: Given the snapshot allowlists, When they are checked against the schema, Then every field is a real column and none is forbidden', () => {
    for (const [entity, config] of Object.entries(SNAPSHOT_CONFIGS)) {
      const columns = columnsOf(config.model);

      expect({ entity, key: columns.includes(config.key) }).toEqual({
        entity,
        key: true,
      });
      expect({
        entity,
        unknown: config.fields.filter((field) => !columns.includes(field)),
        forbidden: config.fields.filter((field) =>
          FORBIDDEN_SNAPSHOT_FIELDS.includes(field),
        ),
      }).toEqual({ entity, unknown: [], forbidden: [] });
    }
    expect(SNAPSHOT_CONFIGS.users.fields).not.toContain('password_hash');
  });

  it('UT-AUDIT-020: Given an entity and ID, When a snapshot is loaded, Then select only allowlisted columns and fall back to null without throwing', async () => {
    const { recorder, findUnique } = setup();
    findUnique.mockResolvedValueOnce({ base_price: new Prisma.Decimal(150) });

    await expect(recorder.loadSnapshot('menu_items', itemId)).resolves.toEqual({
      base_price: '150',
    });
    expect(findUnique).toHaveBeenCalledWith({
      where: { menu_item_id: itemId },
      select: Object.fromEntries(
        SNAPSHOT_CONFIGS.menu_items.fields.map((field) => [field, true]),
      ),
    });

    findUnique.mockClear();
    await expect(
      recorder.loadSnapshot('menu_items', 'abc'),
    ).resolves.toBeNull();
    await expect(recorder.loadSnapshot('things', itemId)).resolves.toBeNull();
    expect(findUnique).not.toHaveBeenCalled();

    findUnique.mockRejectedValueOnce(new Error('db at 10.0.0.5 refused'));
    await expect(
      recorder.loadSnapshot('menu_items', itemId),
    ).resolves.toBeNull();
    expect(errorLog).toHaveBeenCalledWith(
      'Failed to load menu_items audit snapshot.',
    );
    expect(JSON.stringify(errorLog.mock.calls)).not.toContain('10.0.0.5');
  });

  it('UT-AUDIT-021: Given snapshots, When success and failure rows are written, Then only the success row stores them', async () => {
    const { recorder, create } = setup();
    const req = request(updateItem, { id: itemId });

    await recorder.recordSuccess(req, undefined, {
      before: { base_price: '150' },
      after: { base_price: '165' },
    });
    await recorder.recordFailure(
      req,
      new ConflictException({ code: 'MENU_ITEM_CONFLICT' }),
    );

    const [success, failure] = (
      create.mock.calls as Array<[{ data: Record<string, unknown> }]>
    ).map(([{ data }]) => data);
    expect(success).toMatchObject({
      outcome: AuditOutcome.SUCCESS,
      before_data: { base_price: '150' },
      after_data: { base_price: '165' },
    });
    expect(failure.outcome).toBe(AuditOutcome.FAILED);
    expect(failure).not.toHaveProperty('before_data');
    expect(failure).not.toHaveProperty('after_data');
  });

  it('UT-AUDIT-022: Given a snapshot on an entity without an allowlist, When the decorator is created, Then throw at startup', () => {
    expect(() =>
      Audit({ action: 'THING_UPDATED', entity: 'things', snapshot: 'update' }),
    ).toThrow('No audit snapshot allowlist for entity: things');
    expect(() => Audit(updateItem)).not.toThrow();
  });

  it('UT-AUDIT-023: Given update, create and failing handlers, When the interceptor runs, Then read before the handler, after on success, and nothing after a failure', async () => {
    const { recorder, findUnique } = setup();
    const record = jest.spyOn(recorder, 'recordSuccess');
    const interceptor = new AuditInterceptor(recorder);
    const order: string[] = [];
    findUnique.mockImplementation(() => {
      order.push('read');
      return Promise.resolve({ is_available: order.length === 1 });
    });
    const handler = (result: unknown) => ({
      handle: () =>
        defer(() => {
          order.push('handler');
          return of(result);
        }),
    });

    const update = request(updateItem, { id: itemId });
    await firstValueFrom(
      interceptor.intercept(httpContext(update), handler({})),
    );
    expect(order).toEqual(['read', 'handler', 'read']);
    expect(record).toHaveBeenLastCalledWith(
      update,
      {},
      {
        before: { is_available: true },
        after: { is_available: false },
      },
    );

    order.length = 0;
    const create = request({
      action: 'MENU_ITEM_CREATED',
      entity: 'menu_items',
      id: fromResult('menu_item_id'),
      snapshot: 'create',
    });
    findUnique.mockResolvedValueOnce({ name: 'New item' });
    await firstValueFrom(
      interceptor.intercept(
        httpContext(create),
        handler({ menu_item_id: itemId }),
      ),
    );
    expect(findUnique).toHaveBeenLastCalledWith(
      expect.objectContaining({ where: { menu_item_id: itemId } }),
    );
    expect(record).toHaveBeenLastCalledWith(
      create,
      { menu_item_id: itemId },
      { before: null, after: { name: 'New item' } },
    );

    findUnique.mockClear();
    record.mockClear();
    await expect(
      firstValueFrom(
        interceptor.intercept(httpContext(update), {
          handle: () => throwError(() => new ConflictException()),
        }),
      ),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(findUnique).toHaveBeenCalledTimes(1);
    expect(record).not.toHaveBeenCalled();
  });
});
