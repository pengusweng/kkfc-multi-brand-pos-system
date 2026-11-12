import { useId } from "react";
import FilterChip from "@/src/components/ui/atoms/filter-chip";
import type { AuditOutcomeCounts, AuditOutcomeFilter } from "../../schemas/auditLogSchema";

const FILTERS: { value: AuditOutcomeFilter; label: string }[] = [
  { value: "all", label: "All" },
  { value: "SUCCESS", label: "Success" },
  { value: "DENIED", label: "Denied" },
  { value: "FAILED", label: "Failed" },
];

type OutcomeFilterProps = {
  value: AuditOutcomeFilter;
  onChange: (outcome: AuditOutcomeFilter) => void;
  counts: AuditOutcomeCounts;
};

export default function OutcomeFilter({ value, onChange, counts }: OutcomeFilterProps) {
  const pillId = useId();

  return (
    <div role="group" aria-label="Filter by outcome" className="isolate flex flex-wrap gap-2">
      {FILTERS.map((filter) => (
        <FilterChip
          key={filter.value}
          label={filter.label}
          count={counts[filter.value]}
          selected={value === filter.value}
          onClick={() => onChange(filter.value)}
          pillId={pillId}
        />
      ))}
    </div>
  );
}
