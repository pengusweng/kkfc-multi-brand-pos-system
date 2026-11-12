import { auditLogsPageSchema, type AuditLogsPage, type AuditOutcomeFilter } from "../schemas/auditLogSchema";

export type AuditLogFilters = {
  outcome: AuditOutcomeFilter;
  /** Exact action code, e.g. USER_UPDATED. */
  action?: string;
  /** Actor name or username. */
  search?: string;
  /** Asia/Manila YYYY-MM-DD, inclusive. */
  from?: string;
  to?: string;
};

export type GetAuditLogsParams = AuditLogFilters & { page: number; limit: number };

export async function getAuditLogs({
  page,
  limit,
  outcome,
  action,
  search,
  from,
  to,
}: GetAuditLogsParams): Promise<AuditLogsPage> {
  const params = new URLSearchParams({ page: String(page), limit: String(limit) });
  if (outcome !== "all") params.set("outcome", outcome);
  if (action) params.set("action", action);
  if (search) params.set("search", search);
  if (from) params.set("from", from);
  if (to) params.set("to", to);

  let response: Response;
  try {
    response = await fetch(`/api/audit-logs?${params}`, {
      headers: { Accept: "application/json" },
      cache: "no-store",
      signal: AbortSignal.timeout(10_000),
    });
  } catch {
    throw new Error("Unable to reach the server. Please try again.");
  }

  if (response.status === 401) throw new Error("Your session has expired. Please sign in again.");
  if (response.status === 403) throw new Error("You don't have permission to view the audit history.");
  if (!response.ok) throw new Error("Unable to load the audit history. Please try again.");

  const body: unknown = await response.json().catch(() => null);
  const result = auditLogsPageSchema.safeParse(body);
  if (!result.success) throw new Error("The server returned an invalid audit history.");

  return result.data;
}
