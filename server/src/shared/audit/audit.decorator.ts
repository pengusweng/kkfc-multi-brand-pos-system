import { SetMetadata } from '@nestjs/common';
import type { Request } from 'express';

export const AUDIT_KEY = 'audit:event';
export const NO_AUDIT_KEY = 'audit:skip';

/** Request fields the audit pipeline reads and sets. */
export type AuditableRequest = Request & {
  audit?: AuditOptions;
  auditRequestId?: string;
  session?: { user_id?: string; user?: { user_id?: string } };
};

/** Reads an ID from the request or the handler's result. */
export type AuditResolver = (
  request: AuditableRequest,
  result?: unknown,
) => unknown;

export interface AuditOptions {
  /** `<ENTITY>_<PAST_VERB>`, e.g. `ORDER_CONFIRMED`. */
  action: string;
  /** Table name from the Prisma `@@map`, e.g. `orders`. */
  entity: string;
  /** Affected entity's UUID. Anything that is not a UUID is stored as null. */
  id?: AuditResolver;
  /** Actor override for routes without a session (e.g. login). */
  actor?: AuditResolver;
}

const ACTION_PATTERN = /^[A-Z][A-Z0-9_]{0,99}$/;
const ENTITY_PATTERN = /^[a-z][a-z0-9_]{0,63}$/;

/**
 * Records a SUCCESS row when the handler completes, and a DENIED (401/403) or
 * FAILED (409/5xx) row when it throws, including guard rejections. Rows hold
 * metadata only. Do not use on `@Sse()` routes.
 */
export function Audit(options: AuditOptions) {
  if (!ACTION_PATTERN.test(options.action)) {
    throw new Error(`Invalid audit action: ${options.action}`);
  }
  if (!ENTITY_PATTERN.test(options.entity)) {
    throw new Error(`Invalid audit entity: ${options.entity}`);
  }
  return SetMetadata(AUDIT_KEY, options);
}

/** Explicitly opts an action route out of auditing; the reason is required. */
export function NoAudit(reason: string) {
  if (!reason.trim()) throw new Error('NoAudit requires a reason.');
  return SetMetadata(NO_AUDIT_KEY, reason);
}

/** Resolves the entity ID from a route parameter. */
export const fromParam =
  (name: string): AuditResolver =>
  (request) =>
    request.params?.[name];

/** Resolves the entity ID from a top-level field of the handler's result. */
export const fromResult =
  (key: string): AuditResolver =>
  (_request, result) =>
    result !== null && typeof result === 'object'
      ? (result as Record<string, unknown>)[key]
      : undefined;
