import { RequestMethod, Type } from '@nestjs/common';
import { METHOD_METADATA, PATH_METADATA } from '@nestjs/common/constants';
import { AppModule } from '../../../app.module';
import { AUDIT_KEY, NO_AUDIT_KEY } from '../audit.decorator';

/**
 * Controllers not yet migrated to `@Audit()`. Remove each module's entries as
 * its rollout step lands; when this is empty every action endpoint is covered.
 */
const PENDING = new Set<string>([
  'KitchenTicketController', // kitchen
  'KitchenFulfillmentController', // kitchen
  'MenuCatalogController', // menu
  'MenuChannelsController', // menu
  'MenuItemModifiersController', // menu
  'MenuItemsController', // menu
  'ModifiersController', // menu
  'RecipesController', // recipe
  'AssetsController', // assets
  'AuditController', // audit
]);

/** GET routes that expose confidential or security data and must be audited. */
const SENSITIVE_READS = [
  'AuditController.findAll',
  'RecipesController.findOne',
  'AssetsController.download',
  'UsersController.findAll',
  'UsersController.findOne',
];

const ACTION_METHODS = new Set([
  RequestMethod.POST,
  RequestMethod.PUT,
  RequestMethod.PATCH,
  RequestMethod.DELETE,
]);

type DynamicModuleRef = {
  module?: Type;
  imports?: unknown[];
  controllers?: Type[];
};

function collectControllers(ref: unknown, seen = new Set<unknown>()): Type[] {
  if (!ref || ref instanceof Promise) return []; // async dynamic modules (config)
  const forward = (ref as { forwardRef?: () => unknown }).forwardRef;
  if (forward) return collectControllers(forward(), seen);

  const dynamic = typeof ref === 'object' ? (ref as DynamicModuleRef) : null;
  const moduleClass = (dynamic ? dynamic.module : ref) as Type | undefined;
  if (!moduleClass || seen.has(moduleClass)) return [];
  seen.add(moduleClass);

  const read = <T>(key: string) =>
    (Reflect.getMetadata(key, moduleClass) as T[] | undefined) ?? [];
  const controllers = [
    ...read<Type>('controllers'),
    ...((dynamic && 'controllers' in dynamic ? dynamic.controllers : []) ?? []),
  ];
  const imports = [
    ...read<unknown>('imports'),
    ...((dynamic && 'imports' in dynamic ? dynamic.imports : []) ?? []),
  ];
  return [
    ...controllers,
    ...imports.flatMap((child) => collectControllers(child, seen)),
  ];
}

function routes(controller: Type) {
  return Object.getOwnPropertyNames(controller.prototype)
    .filter((name) => name !== 'constructor')
    .map((name) => {
      const handler = (controller.prototype as Record<string, unknown>)[name];
      return {
        id: `${controller.name}.${name}`,
        controller: controller.name,
        method: Reflect.getMetadata(METHOD_METADATA, handler as object) as
          RequestMethod | undefined,
        path: Reflect.getMetadata(PATH_METADATA, handler as object) as unknown,
        audited:
          Reflect.getMetadata(AUDIT_KEY, handler as object) !== undefined,
        skipped: Reflect.getMetadata(NO_AUDIT_KEY, handler as object) as
          string | undefined,
      };
    })
    .filter((route) => route.method !== undefined && route.path !== undefined);
}

describe('Audit coverage', () => {
  const controllers = [...new Set(collectControllers(AppModule))];
  const allRoutes = controllers.flatMap(routes);

  it('UT-AUDIT-015: Given the application controllers, When routes are discovered, Then known controllers and action routes are found', () => {
    const names = controllers.map((controller) => controller.name);

    expect(names).toEqual(
      expect.arrayContaining([
        'OrdersController',
        'KitchenFulfillmentController',
      ]),
    );
    expect(allRoutes.some((route) => ACTION_METHODS.has(route.method!))).toBe(
      true,
    );
    // A stale allowlist entry would silently stop protecting nothing.
    expect([...PENDING].filter((name) => !names.includes(name))).toEqual([]);
  });

  it('UT-AUDIT-016: Given migrated controllers, When action routes are checked, Then each has @Audit or @NoAudit, never both', () => {
    const missing = allRoutes.filter(
      (route) =>
        !PENDING.has(route.controller) &&
        ACTION_METHODS.has(route.method!) &&
        !route.audited &&
        !route.skipped,
    );
    const both = allRoutes.filter((route) => route.audited && route.skipped);

    expect(missing.map((route) => route.id)).toEqual([]);
    expect(both.map((route) => route.id)).toEqual([]);
  });

  it('UT-AUDIT-017: Given migrated controllers, When sensitive reads are checked, Then each is audited', () => {
    const ids = new Set(allRoutes.map((route) => route.id));
    const unknown = SENSITIVE_READS.filter((id) => !ids.has(id));
    const unaudited = allRoutes.filter(
      (route) =>
        SENSITIVE_READS.includes(route.id) &&
        !PENDING.has(route.controller) &&
        !route.audited,
    );

    expect(unknown).toEqual([]);
    expect(unaudited.map((route) => route.id)).toEqual([]);
  });
});
