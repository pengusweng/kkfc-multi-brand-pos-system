import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { getAuditLogs, type AuditLogFilters } from "../services/audit-logs.service";
import { AUDIT_PAGE_SIZE } from "../utils/audit";

// One request per page. The previous page stays in `data` (isPlaceholderData)
// until the requested one arrives, so counts and totals don't blank out.
export function useAuditLogs({ page, ...filters }: AuditLogFilters & { page: number }) {
  return useQuery({
    queryKey: ["audit-logs", { ...filters, page, limit: AUDIT_PAGE_SIZE }],
    queryFn: () => getAuditLogs({ ...filters, page, limit: AUDIT_PAGE_SIZE }),
    placeholderData: keepPreviousData,
    retry: false,
  });
}
