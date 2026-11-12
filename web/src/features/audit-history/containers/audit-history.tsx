"use client";

import { useState } from "react";
import Pagination from "@/src/components/ui/molecules/pagination";
import PageTitle from "@/src/features/dashboard/components/atoms/page-title";
import { useDebouncedValue } from "@/src/hooks/useDebouncedValue";
import AuditDetailModal from "../components/organisms/audit-detail-modal";
import AuditFilterBar from "../components/organisms/audit-filter-bar";
import AuditTable from "../components/organisms/audit-table";
import { useAuditLogs } from "../hooks/useAuditLogs";
import type { AuditOutcomeCounts, AuditOutcomeFilter } from "../schemas/auditLogSchema";
import { AUDIT_PAGE_SIZE, todayInManila, toAuditEntry, type AuditEntry } from "../utils/audit";

const NO_COUNTS: AuditOutcomeCounts = { all: 0, SUCCESS: 0, DENIED: 0, FAILED: 0 };

export default function AuditHistoryPage() {
  const [query, setQuery] = useState("");
  const [outcome, setOutcome] = useState<AuditOutcomeFilter>("all");
  const [action, setAction] = useState<string | undefined>();
  const [dates, setDates] = useState<{ from?: string; to?: string }>({});
  const search = useDebouncedValue(query.trim());

  // Kept after closing so the dialog's content doesn't blank out mid-exit.
  const [viewing, setViewing] = useState<AuditEntry | null>(null);
  const [modalOpen, setModalOpen] = useState(false);

  // Any filter change returns to page 1.
  const filterKey = `${outcome}|${action ?? ""}|${search}|${dates.from ?? ""}|${dates.to ?? ""}`;
  const [paging, setPaging] = useState({ filterKey, page: 1 });
  if (paging.filterKey !== filterKey) setPaging({ filterKey, page: 1 });
  const page = paging.filterKey === filterKey ? paging.page : 1;

  const { data, error, isPending, isPlaceholderData } = useAuditLogs({
    page,
    outcome,
    action,
    search,
    from: dates.from,
    to: dates.to,
  });

  const entries = data?.data.map(toAuditEntry) ?? [];
  const meta = data?.meta;
  const total = meta?.total ?? 0;
  const filtered = Boolean(query.trim() || action || dates.from || dates.to || outcome !== "all");

  let emptyMessage = "No entries match these filters.";
  if (error) emptyMessage = error.message;
  else if (!filtered) emptyMessage = "No audit entries yet.";

  return (
    <section className="motion-safe:animate-page-in">
      <PageTitle>Audit history</PageTitle>

      <AuditFilterBar
        query={query}
        onQueryChange={setQuery}
        action={action}
        onActionChange={setAction}
        dates={dates}
        onDatesChange={setDates}
        maxDate={todayInManila()}
        outcome={outcome}
        onOutcomeChange={setOutcome}
        counts={meta?.counts ?? NO_COUNTS}
        resultCount={total}
        onClear={
          filtered
            ? () => {
                setQuery("");
                setAction(undefined);
                setDates({});
                setOutcome("all");
              }
            : undefined
        }
      />

      <AuditTable
        entries={entries}
        onView={(entry) => {
          setViewing(entry);
          setModalOpen(true);
        }}
        loading={isPending || isPlaceholderData}
        skeletonRows={entries.length || AUDIT_PAGE_SIZE}
        emptyMessage={emptyMessage}
        footer={
          total > 0 ? (
            <Pagination
              page={page}
              pageSize={AUDIT_PAGE_SIZE}
              total={total}
              totalPages={meta?.totalPages ?? 1}
              onPageChange={(next) => setPaging({ filterKey, page: next })}
            />
          ) : null
        }
      />

      <AuditDetailModal entry={viewing} open={modalOpen} onOpenChange={setModalOpen} />
    </section>
  );
}
