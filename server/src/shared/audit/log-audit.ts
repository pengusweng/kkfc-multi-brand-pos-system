import { AuditOutcome, Prisma } from '@prisma/client';

// Metadata only: callers cannot accidentally persist request bodies, credentials,
// confidential recipe snapshots or exception messages in this shared writer.
// `reason` is a machine error code (e.g. KITCHEN_TICKET_INVALID_STATUS), never a
// free-text message.
export async function logAudit(
  db: Pick<Prisma.TransactionClient, 'auditLog'>,
  event: {
    actor_id: string | null;
    action: string;
    entity_type: string;
    entity_id: string | null;
    outcome: AuditOutcome;
    reason?: string | null;
    request_id?: string | null;
  },
) {
  await db.auditLog.create({
    data: {
      actor_id: event.actor_id,
      action: event.action,
      entity_type: event.entity_type,
      entity_id: event.entity_id,
      outcome: event.outcome,
      // Omitted unless set; both columns default to null.
      ...(event.reason != null ? { reason: event.reason } : {}),
      ...(event.request_id != null ? { request_id: event.request_id } : {}),
    },
  });
}
