import { z } from "zod";
import { userRoleSchema } from "@/src/features/staff/schemas/userSchema";

export const auditOutcomeSchema = z.enum(["SUCCESS", "DENIED", "FAILED"]);

/** A JSON snapshot of allowlisted columns; its shape depends on entity_type. */
export const auditSnapshotSchema = z.record(z.string(), z.unknown());

// The API types snapshots as any JSON; anything but an object can't be shown
// field by field, so it is dropped rather than failing the whole page.
const snapshotField = auditSnapshotSchema.nullable().catch(null);

/** Only the actor's display identity is exposed, never the full user record. */
export const auditActorSchema = z.object({
  username: z.string(),
  first_name: z.string(),
  last_name: z.string(),
  role: userRoleSchema,
});

// IDs are Postgres uuid columns; z.guid() accepts any UUID shape (seeded IDs aren't always v4).
// One row of audit_logs, as returned by GET /api/audit-logs.
export const auditLogSchema = z.object({
  audit_log_id: z.guid(),
  actor_id: z.guid().nullable(),
  /** Machine code, e.g. USER_UPDATED. */
  action: z.string(),
  /** Table the action touched, e.g. users, menu_items. */
  entity_type: z.string(),
  entity_id: z.guid().nullable(),
  outcome: auditOutcomeSchema,
  /** Error code for DENIED / FAILED rows, e.g. ACCESS_DENIED. */
  reason: z.string().nullable(),
  before_data: snapshotField,
  after_data: snapshotField,
  request_id: z.string().nullable(),
  created_at: z.iso.datetime(),
  /** null when nobody was signed in, e.g. a failed sign-in. */
  actor: auditActorSchema.nullable(),
});

export const auditLogsPageSchema = z.object({
  data: z.array(auditLogSchema),
  meta: z.object({
    page: z.number().int(),
    limit: z.number().int(),
    total: z.number().int(),
    totalPages: z.number().int(),
    /** Per outcome under every filter except outcome, for labelling the outcome chips. */
    counts: z.object({
      all: z.number().int(),
      SUCCESS: z.number().int(),
      DENIED: z.number().int(),
      FAILED: z.number().int(),
    }),
  }),
});

export type AuditOutcomeCode = z.infer<typeof auditOutcomeSchema>;
export type AuditOutcomeFilter = "all" | AuditOutcomeCode;
export type AuditOutcomeCounts = Record<AuditOutcomeFilter, number>;
export type AuditSnapshot = z.infer<typeof auditSnapshotSchema>;
export type AuditActorRecord = z.infer<typeof auditActorSchema>;
export type AuditLog = z.infer<typeof auditLogSchema>;
export type AuditLogsPage = z.infer<typeof auditLogsPageSchema>;
