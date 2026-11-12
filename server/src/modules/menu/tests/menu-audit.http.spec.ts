import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { Prisma, UserRole } from '@prisma/client';
import {
  auditPipelineProviders,
  createAuditSpy,
} from '../../../shared/testing/audit.testing';
import { AssetsService } from '../../assets/assets.service';
import { AuthService } from '../../auth/auth.service';
import { MenuCatalogController } from '../menu-catalog/menu-catalog.controller';
import { MenuCatalogService } from '../menu-catalog/menu-catalog.service';
import { MenuChannelsController } from '../menu-channels/menu-channels.controller';
import { MenuChannelsService } from '../menu-channels/menu-channels.service';
import { MenuItemModifiersController } from '../menu-item-modifiers/menu-item-modifiers.controller';
import { MenuItemModifiersService } from '../menu-item-modifiers/menu-item-modifiers.service';
import { MenuItemsController } from '../menu-items/menu-items.controller';
import { MenuItemsService } from '../menu-items/menu-items.service';
import { ModifiersController } from '../modifiers/modifiers.controller';
import { ModifiersService } from '../modifiers/modifiers.service';

const actorId = '11111111-1111-4111-8111-111111111111';
const routeId = '22222222-2222-4222-8222-222222222222';
const createdId = '33333333-3333-4333-8333-333333333333';

// Every create returns `createdId` in each menu ID field and every other route
// targets `routeId`, so each row proves where its entity ID came from.
const created = {
  menu_item_id: createdId,
  menu_item_channel_id: createdId,
  modifier_id: createdId,
  menu_item_modifier_id: createdId,
};

const mockService = (methods: string[]) =>
  Object.fromEntries(methods.map((name) => [name, jest.fn()])) as Record<
    string,
    jest.Mock
  >;

// DTO validation is covered by each menu module's own HTTP spec; this spec
// only checks which audit rows each menu action produces.
describe('Menu audit logging', () => {
  let app: INestApplication;
  let url: string;
  let role: UserRole;
  const audit = createAuditSpy();
  const services = {
    catalog: mockService(['create', 'findAll']),
    channels: mockService([
      'create',
      'findAll',
      'findManyByMenuItem',
      'findOne',
      'update',
      'reactivate',
      'delete',
    ]),
    items: mockService([
      'createMenuItem',
      'findOneMenuItem',
      'findAll',
      'findAllByBrand',
      'updateMenuItem',
      'updateAvailability',
      'reactivateMenuItem',
      'deleteMenuItem',
    ]),
    modifiers: mockService([
      'create',
      'findAll',
      'findOne',
      'update',
      'reactivate',
      'delete',
    ]),
    itemModifiers: mockService([
      'create',
      'findAll',
      'findManyForMenuItem',
      'findOne',
      'update',
      'reactivate',
      'delete',
    ]),
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
      controllers: [
        MenuCatalogController,
        MenuChannelsController,
        MenuItemsController,
        ModifiersController,
        MenuItemModifiersController,
      ],
      providers: [
        { provide: MenuCatalogService, useValue: services.catalog },
        { provide: MenuChannelsService, useValue: services.channels },
        { provide: MenuItemsService, useValue: services.items },
        { provide: ModifiersService, useValue: services.modifiers },
        { provide: MenuItemModifiersService, useValue: services.itemModifiers },
        { provide: AssetsService, useValue: { upload: jest.fn() } },
        { provide: AuthService, useValue: auth },
        ...auditPipelineProviders(audit),
      ],
    }).compile();
    app = module.createNestApplication();
    app.useLogger(false);
    app.setGlobalPrefix('api');
    await app.listen(0);
    url = `${await app.getUrl()}/api`;
  });

  afterAll(async () => app.close());

  beforeEach(() => {
    role = UserRole.SUPERADMIN;
    audit.create.mockClear().mockResolvedValue({});
    for (const service of Object.values(services)) {
      for (const mock of Object.values(service)) {
        mock.mockReset().mockResolvedValue(created);
      }
    }
  });

  function call(method: string, path: string, body: unknown = {}) {
    return fetch(`${url}${path}`, {
      method,
      headers: {
        Authorization: 'Bearer token',
        'Content-Type': 'application/json',
      },
      body: method === 'GET' ? undefined : JSON.stringify(body),
    });
  }

  const crud = (base: string, prefix: string, entity: string) => [
    ['POST', base, `${prefix}_CREATED`, entity, createdId],
    ['PATCH', `${base}/${routeId}`, `${prefix}_UPDATED`, entity, routeId],
    [
      'PATCH',
      `${base}/reactivate/${routeId}`,
      `${prefix}_REACTIVATED`,
      entity,
      routeId,
    ],
    ['DELETE', `${base}/${routeId}`, `${prefix}_DEACTIVATED`, entity, routeId],
  ];

  it.each([
    [
      'POST',
      '/menu-catalog',
      'MENU_CATALOG_ENTRY_CREATED',
      'menu_items',
      createdId,
    ],
    ...crud('/menu-channels', 'MENU_ITEM_CHANNEL', 'menu_item_channels'),
    ...crud('/menu-items', 'MENU_ITEM', 'menu_items'),
    [
      'PATCH',
      `/menu-items/availability/${routeId}`,
      'MENU_ITEM_AVAILABILITY_CHANGED',
      'menu_items',
      routeId,
    ],
    ...crud('/modifiers', 'MODIFIER', 'modifiers'),
    ...crud(
      '/menu-item-modifiers',
      'MENU_ITEM_MODIFIER',
      'menu_item_modifiers',
    ),
  ])(
    'IT-MENU-001: Given a superadmin, When %s %s succeeds, Then audit %s on %s for the affected record',
    async (method, path, action, entity, entityId) => {
      const response = await call(method, path, { availability: false });

      expect(response.ok).toBe(true);
      expect(audit.rows()).toEqual([
        expect.objectContaining({
          actor_id: actorId,
          action,
          entity_type: entity,
          entity_id: entityId,
          outcome: 'SUCCESS',
        }),
      ]);
    },
  );

  it('IT-MENU-002: Given a duplicate modifier code and an already inactive menu item, When they are saved or deactivated, Then audit the conflict but not the missing record', async () => {
    services.modifiers.create.mockRejectedValue(
      new Prisma.PrismaClientKnownRequestError('Unique', {
        code: 'P2002',
        clientVersion: 'test',
      }),
    );
    services.items.deleteMenuItem.mockRejectedValue(
      new Prisma.PrismaClientKnownRequestError('Missing', {
        code: 'P2025',
        clientVersion: 'test',
      }),
    );

    const duplicate = await call('POST', '/modifiers');
    const inactive = await call('DELETE', `/menu-items/${routeId}`);

    expect([duplicate.status, inactive.status]).toEqual([409, 404]);
    expect(audit.rows()).toEqual([
      expect.objectContaining({
        action: 'MODIFIER_CREATED',
        entity_id: null,
        outcome: 'FAILED',
        reason: 'DUPLICATE_RESOURCE',
      }),
    ]);
  });

  it('IT-MENU-003: Given kitchen staff, When they list all menu items, mark an item unavailable and try to create one, Then audit the toggle and the denied create but not the denied read', async () => {
    role = UserRole.KITCHEN_STAFF;

    // Superadmin-only list: denied, but reads are unaudited even when denied.
    const read = await call('GET', '/menu-items');
    // Kitchen staff may mark items sold out; the row records who did it.
    const toggle = await call('PATCH', `/menu-items/availability/${routeId}`, {
      availability: false,
    });
    const create = await call('POST', '/menu-items');

    expect([read.status, toggle.status, create.status]).toEqual([
      403, 200, 403,
    ]);
    expect(services.items.createMenuItem).not.toHaveBeenCalled();
    expect(audit.rows()).toEqual([
      expect.objectContaining({
        actor_id: actorId,
        action: 'MENU_ITEM_AVAILABILITY_CHANGED',
        entity_id: routeId,
        outcome: 'SUCCESS',
      }),
      expect.objectContaining({
        actor_id: actorId,
        action: 'MENU_ITEM_CREATED',
        entity_id: null,
        outcome: 'DENIED',
        reason: 'ACCESS_DENIED',
      }),
    ]);
  });
});
