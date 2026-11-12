import { Provider } from '@nestjs/common';
import { APP_FILTER, APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { AuditContextGuard } from '../audit/audit-context.guard';
import { AuditRecorder } from '../audit/audit-recorder.service';
import { AuditInterceptor } from '../audit/audit.interceptor';
import { AllExceptionsFilter } from '../filters/all-exceptions.filter';
import { PrismaExceptionFilter } from '../filters/prisma-exception.filter';
import { PrismaService } from '../prisma/prisma.service';

/**
 * An in-memory audit table for HTTP specs: inspect `rows()` after requests.
 * Snapshot reads go through `findUnique` (any model), which returns null unless
 * a test queues rows, e.g. `spy.findUnique.mockResolvedValueOnce(before)`.
 */
export function createAuditSpy() {
  const create = jest.fn().mockResolvedValue({});
  const findUnique = jest.fn().mockResolvedValue(null);
  return {
    create,
    findUnique,
    /** Clears recorded rows and queued snapshot rows between tests. */
    reset() {
      create.mockReset().mockResolvedValue({});
      findUnique.mockReset().mockResolvedValue(null);
    },
    rows: () =>
      (create.mock.calls as Array<[{ data: Record<string, unknown> }]>).map(
        ([{ data }]) => data,
      ),
  };
}

/**
 * The global audit pipeline (guard, interceptor, filters) as wired in
 * AppModule, writing to the given spy instead of the database.
 */
export function auditPipelineProviders(
  spy: ReturnType<typeof createAuditSpy>,
): Provider[] {
  // `auditLog` writes rows; every other model answers snapshot reads.
  const prisma = new Proxy(
    {},
    {
      get: (_target, model) =>
        model === 'auditLog'
          ? { create: spy.create }
          : { findUnique: spy.findUnique },
    },
  );
  return [
    {
      provide: AuditRecorder,
      useFactory: () => new AuditRecorder(prisma as PrismaService),
    },
    { provide: APP_FILTER, useClass: AllExceptionsFilter },
    { provide: APP_FILTER, useClass: PrismaExceptionFilter },
    { provide: APP_GUARD, useClass: AuditContextGuard },
    { provide: APP_INTERCEPTOR, useClass: AuditInterceptor },
  ];
}
