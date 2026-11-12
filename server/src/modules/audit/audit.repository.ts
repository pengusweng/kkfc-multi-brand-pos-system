import { Injectable } from '@nestjs/common';
import { AuditOutcome, Prisma } from '@prisma/client';
import { PrismaService } from '../../shared/prisma/prisma.service';
import type { FindAuditLogsDTO } from './dto/find-audit-logs.dto';

// Deliberate API field allowlist: future schema fields must be reviewed before
// becoming visible in responses. Never include the actor's full User record:
// only the display identity the audit history needs.
export const AUDIT_ACTOR_SELECT = {
  username: true,
  first_name: true,
  last_name: true,
  role: true,
} as const satisfies Prisma.UserSelect;

export const AUDIT_LOG_SELECT = {
  audit_log_id: true,
  actor_id: true,
  action: true,
  entity_type: true,
  entity_id: true,
  outcome: true,
  reason: true,
  before_data: true,
  after_data: true,
  request_id: true,
  created_at: true,
  actor: { select: AUDIT_ACTOR_SELECT },
} as const satisfies Prisma.AuditLogSelect;

export type AuditLogFilters = Pick<
  FindAuditLogsDTO,
  'action' | 'search' | 'from' | 'to'
>;

const DAY_MS = 24 * 60 * 60 * 1000;

/** Midnight at the start of a YYYY-MM-DD date in Asia/Manila (UTC+8, no DST). */
function manilaMidnight(date: string): Date {
  return new Date(`${date}T00:00:00+08:00`);
}

@Injectable()
export class AuditRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(
    filters: AuditLogFilters,
    outcome: AuditOutcome | undefined,
    skip: number,
    take: number,
  ) {
    // Everything except outcome, which the per-outcome counts below vary.
    const matchesFilters = this.filtersWhere(filters);
    const countOf = (value: AuditOutcome) =>
      this.prisma.auditLog.count({
        where: { ...matchesFilters, outcome: value },
      });

    const [logs, success, denied, failed] = await this.prisma.$transaction(
      [
        this.prisma.auditLog.findMany({
          where: { ...matchesFilters, ...(outcome ? { outcome } : {}) },
          skip,
          take,
          select: AUDIT_LOG_SELECT,
          orderBy: [{ created_at: 'desc' }, { audit_log_id: 'asc' }],
        }),
        countOf(AuditOutcome.SUCCESS),
        countOf(AuditOutcome.DENIED),
        countOf(AuditOutcome.FAILED),
      ],
      { isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead },
    );
    // Per-outcome counts honour every other filter, so a client can label
    // each outcome tab from a single response.
    const counts = {
      all: success + denied + failed,
      SUCCESS: success,
      DENIED: denied,
      FAILED: failed,
    };
    return { logs, total: counts[outcome ?? 'all'], counts };
  }

  private filtersWhere({
    action,
    search,
    from,
    to,
  }: AuditLogFilters): Prisma.AuditLogWhereInput {
    const terms = search?.split(/\s+/).filter(Boolean) ?? [];
    return {
      ...(action !== undefined ? { action } : {}),
      ...(from !== undefined || to !== undefined
        ? {
            created_at: {
              ...(from !== undefined ? { gte: manilaMidnight(from) } : {}),
              // Inclusive of the whole "to" day: before the next midnight.
              ...(to !== undefined
                ? { lt: new Date(manilaMidnight(to).getTime() + DAY_MS) }
                : {}),
            },
          }
        : {}),
      // Every whitespace-separated term must match the actor's username,
      // first name, or last name, so "ana rey" finds Ana Reyes.
      ...(terms.length > 0
        ? {
            AND: terms.map((term) => ({
              actor: {
                is: {
                  OR: (['username', 'first_name', 'last_name'] as const).map(
                    (field) => ({
                      [field]: { contains: term, mode: 'insensitive' as const },
                    }),
                  ),
                },
              },
            })),
          }
        : {}),
    };
  }
}
