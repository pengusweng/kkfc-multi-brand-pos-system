"use client";

import SearchField from "@/src/components/ui/molecules/search-field";
import type { AuditOutcomeCounts, AuditOutcomeFilter } from "../../schemas/auditLogSchema";
import ActionSelect from "../molecules/action-select";
import DateRangeField from "../molecules/date-range-field";
import OutcomeFilter from "../molecules/outcome-filter";

type AuditFilterBarProps = {
  query: string;
  onQueryChange: (query: string) => void;
  action: string | undefined;
  onActionChange: (action: string | undefined) => void;
  dates: { from?: string; to?: string };
  onDatesChange: (dates: { from?: string; to?: string }) => void;
  maxDate: string;
  outcome: AuditOutcomeFilter;
  onOutcomeChange: (outcome: AuditOutcomeFilter) => void;
  counts: AuditOutcomeCounts;
  resultCount: number;
  /** Shown when any filter is set. */
  onClear?: () => void;
};

// Same card as the staff filter bar. Two rows here: what to look for (who,
// what, when) above, and the outcome chips with the result count below.
export default function AuditFilterBar({
  query,
  onQueryChange,
  action,
  onActionChange,
  dates,
  onDatesChange,
  maxDate,
  outcome,
  onOutcomeChange,
  counts,
  resultCount,
  onClear,
}: AuditFilterBarProps) {
  return (
    <div className="mt-6 flex flex-col gap-3 rounded-xl border border-hairline bg-card p-3 md:px-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:flex-wrap sm:items-center sm:gap-x-4">
        <SearchField label="Search actor name or username" value={query} onChange={onQueryChange} />
        <ActionSelect value={action} onChange={onActionChange} />
        <DateRangeField value={dates} onChange={onDatesChange} max={maxDate} />
      </div>
      <div className="flex flex-col gap-3 border-t border-hairline pt-3 sm:flex-row sm:flex-wrap sm:items-center sm:gap-x-4">
        <OutcomeFilter value={outcome} onChange={onOutcomeChange} counts={counts} />
        <div className="flex items-center gap-3 sm:ml-auto">
          {onClear ? (
            <button
              type="button"
              onClick={onClear}
              className="cursor-pointer rounded-md px-1 text-sm font-semibold text-ink underline decoration-hairline underline-offset-4 outline-none hover:decoration-ink focus-visible:ring-2 focus-visible:ring-primary/40"
            >
              Clear filters
            </button>
          ) : null}
          <p aria-live="polite" className="text-sm text-ink-muted tabular-nums">
            {resultCount} {resultCount === 1 ? "entry" : "entries"}
          </p>
        </div>
      </div>
    </div>
  );
}
