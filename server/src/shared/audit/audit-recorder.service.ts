import { HttpException, Injectable, Logger } from '@nestjs/common';
import { AuditOutcome } from '@prisma/client';
import { isUUID } from 'class-validator';
import { PrismaService } from '../prisma/prisma.service';
import type { AuditableRequest } from './audit.decorator';
import { logAudit } from './log-audit';

const CODE_PATTERN = /^[A-Z0-9_]{1,100}$/;

/**
 * Maps a thrown error to an audit outcome. 401/403 and 429 (PIN lockout) are
 * DENIED, 409 and 5xx are FAILED, and everything else (400 validation, 404) is
 * not audited.
 */
export function classifyFailure(
  exception: unknown,
): { outcome: AuditOutcome; reason: string } | null {
  if (!(exception instanceof HttpException)) {
    return { outcome: AuditOutcome.FAILED, reason: 'INTERNAL_ERROR' };
  }

  const status = exception.getStatus();
  const outcome =
    status === 401 || status === 403 || status === 429
      ? AuditOutcome.DENIED
      : status === 409 || status >= 500
        ? AuditOutcome.FAILED
        : null;
  if (!outcome) return null;

  // Only a well-formed error code is stored; free-text messages may echo input.
  const body = exception.getResponse();
  const code =
    body !== null && typeof body === 'object' && 'code' in body
      ? body.code
      : undefined;
  const reason =
    typeof code === 'string' && CODE_PATTERN.test(code)
      ? code
      : `HTTP_${status}`;
  return { outcome, reason };
}

function uuidOrNull(value: unknown): string | null {
  return typeof value === 'string' && isUUID(value) ? value : null;
}

@Injectable()
export class AuditRecorder {
  private readonly logger = new Logger(AuditRecorder.name);

  constructor(private readonly prisma: PrismaService) {}

  async recordSuccess(request: AuditableRequest, result: unknown) {
    await this.write(request, AuditOutcome.SUCCESS, null, result);
  }

  async recordFailure(request: AuditableRequest, exception: unknown) {
    const failure = classifyFailure(exception);
    if (failure) {
      await this.write(request, failure.outcome, failure.reason, undefined);
    }
  }

  /** Never throws: an audit outage must not fail or alter the response. */
  private async write(
    request: AuditableRequest,
    outcome: AuditOutcome,
    reason: string | null,
    result: unknown,
  ) {
    const audit = request.audit;
    if (!audit) return;

    try {
      const actor = audit.actor
        ? audit.actor(request, result)
        : (request.session?.user?.user_id ?? request.session?.user_id);

      await logAudit(this.prisma, {
        actor_id: uuidOrNull(actor),
        action: audit.action,
        entity_type: audit.entity,
        entity_id: uuidOrNull(audit.id?.(request, result)),
        outcome,
        reason,
        request_id: request.auditRequestId ?? null,
      });
    } catch {
      // Constant message: no request data or raw error details in the logs.
      this.logger.error(`Failed to persist ${outcome} audit event.`);
    }
  }
}
