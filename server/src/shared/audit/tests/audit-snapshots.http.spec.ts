import {
  ConflictException,
  Controller,
  INestApplication,
  Param,
  Patch,
  Post,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { Prisma } from '@prisma/client';
import {
  auditPipelineProviders,
  createAuditSpy,
} from '../../testing/audit.testing';
import { Audit, fromParam, fromResult } from '../audit.decorator';

const itemId = '22222222-2222-4222-8222-222222222222';
const newItemId = '33333333-3333-4333-8333-333333333333';

const menuItem = (overrides: Record<string, unknown> = {}) => ({
  code: 'GC-KIMCHI-FRIED-RICE',
  name: 'Kimchi Fried Rice',
  description: null,
  serving_description: null,
  base_price: new Prisma.Decimal('150.00'),
  img_url: 'uploads/kimchi.png',
  is_available: true,
  is_active: true,
  ...overrides,
});

@Controller('items')
class ItemsController {
  @Patch(':id')
  @Audit({
    action: 'MENU_ITEM_UPDATED',
    entity: 'menu_items',
    id: fromParam('id'),
    snapshot: 'update',
  })
  update(@Param('id') id: string) {
    return { menu_item_id: id };
  }

  @Post()
  @Audit({
    action: 'MENU_ITEM_CREATED',
    entity: 'menu_items',
    id: fromResult('menu_item_id'),
    snapshot: 'create',
  })
  create() {
    return { menu_item_id: newItemId };
  }

  @Patch(':id/locked')
  @Audit({
    action: 'MENU_ITEM_UPDATED',
    entity: 'menu_items',
    id: fromParam('id'),
    snapshot: 'update',
  })
  locked() {
    throw new ConflictException({ code: 'MENU_ITEM_LOCKED' });
  }
}

describe('Audit snapshots HTTP', () => {
  let app: INestApplication;
  let url: string;
  const audit = createAuditSpy();

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [ItemsController],
      providers: [...auditPipelineProviders(audit)],
    }).compile();
    app = module.createNestApplication();
    app.useLogger(false);
    await app.listen(0);
    url = `${await app.getUrl()}/items`;
  });

  afterAll(async () => app.close());

  beforeEach(() => audit.reset());

  const send = (method: string, path = '') =>
    fetch(`${url}${path}`, { method });

  it('IT-AUDIT-015: Given a price change, When an update succeeds, Then store only the changed fields before and after', async () => {
    audit.findUnique
      .mockResolvedValueOnce(menuItem())
      .mockResolvedValueOnce(
        menuItem({ base_price: new Prisma.Decimal('165.00') }),
      );

    const response = await send('PATCH', `/${itemId}`);

    expect(response.status).toBe(200);
    expect(audit.rows()).toEqual([
      expect.objectContaining({
        action: 'MENU_ITEM_UPDATED',
        entity_id: itemId,
        outcome: 'SUCCESS',
        before_data: { base_price: '150' },
        after_data: { base_price: '165' },
      }),
    ]);
  });

  it('IT-AUDIT-016: Given a new record, When a create succeeds, Then store the full allowlisted record as after only', async () => {
    audit.findUnique.mockResolvedValueOnce(menuItem());

    const response = await send('POST');
    const [row] = audit.rows();

    expect(response.status).toBe(201);
    expect(row).toMatchObject({
      action: 'MENU_ITEM_CREATED',
      entity_id: newItemId,
      after_data: {
        code: 'GC-KIMCHI-FRIED-RICE',
        name: 'Kimchi Fried Rice',
        description: null,
        serving_description: null,
        base_price: '150',
        img_url: 'uploads/kimchi.png',
        is_available: true,
        is_active: true,
      },
    });
    expect(row).not.toHaveProperty('before_data');
    expect(audit.findUnique).toHaveBeenCalledTimes(1);
  });

  it('IT-AUDIT-017: Given an unchanged record and a rejected update, When they are audited, Then store no snapshots', async () => {
    audit.findUnique.mockResolvedValue(menuItem());

    const unchanged = await send('PATCH', `/${itemId}`);
    const rejected = await send('PATCH', `/${itemId}/locked`);

    expect([unchanged.status, rejected.status]).toEqual([200, 409]);
    const [noChange, conflict] = audit.rows();
    expect(noChange).toMatchObject({ outcome: 'SUCCESS' });
    expect(conflict).toMatchObject({
      outcome: 'FAILED',
      reason: 'MENU_ITEM_LOCKED',
    });
    for (const row of [noChange, conflict]) {
      expect(row).not.toHaveProperty('before_data');
      expect(row).not.toHaveProperty('after_data');
    }
  });
});
