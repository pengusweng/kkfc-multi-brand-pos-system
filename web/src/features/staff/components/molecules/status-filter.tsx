import type { StaffStatusFilter } from "../../utils/staff";
import FilterChip from "@/src/components/ui/atoms/filter-chip";

const FILTERS: { value: StaffStatusFilter; label: string }[] = [
  { value: "all", label: "All" },
  { value: "active", label: "Active" },
  { value: "inactive", label: "Inactive" },
];

type StatusFilterProps = {
  value: StaffStatusFilter;
  onChange: (status: StaffStatusFilter) => void;
  counts: Record<StaffStatusFilter, number>;
};

export default function StatusFilter({ value, onChange, counts }: StatusFilterProps) {
  return (
    <div role="group" aria-label="Filter by status" className="flex flex-wrap gap-2">
      {FILTERS.map((filter) => (
        <FilterChip
          key={filter.value}
          label={filter.label}
          count={counts[filter.value]}
          selected={value === filter.value}
          onClick={() => onChange(filter.value)}
        />
      ))}
    </div>
  );
}
