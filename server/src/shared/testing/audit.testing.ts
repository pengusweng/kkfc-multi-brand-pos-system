import { Provider } from '@nestjs/common';
import { APP_FILTER, APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { AuditContextGuard } from '../audit/audit-context.guard';
import { AuditRecorder } from '../audit/audit-recorder.service';
import { AuditInterceptor } from '../audit/audit.interceptor';
import { AllExceptionsFilter } from '../filters/all-exceptions.filter';
import { PrismaExceptionFilter } from '../filters/prisma-exception.filter';
import { PrismaService } from '../prisma/prisma.service';

/** An in-memory audit table for HTTP specs: inspect `rows()` after requests. */
export function createAuditSpy() {
  const create = jest.fn().mockResolvedValue({});
  return {
    create,
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
  return [
    {
      provide: AuditRecorder,
      useFactory: () =>
        new AuditRecorder({
          auditLog: { create: spy.create },
        } as unknown as PrismaService),
    },
    { provide: APP_FILTER, useClass: AllExceptionsFilter },
    { provide: APP_FILTER, useClass: PrismaExceptionFilter },
    { provide: APP_GUARD, useClass: AuditContextGuard },
    { provide: APP_INTERCEPTOR, useClass: AuditInterceptor },
  ];
}
