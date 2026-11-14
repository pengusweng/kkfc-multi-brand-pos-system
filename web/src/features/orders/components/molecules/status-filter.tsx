import { useId } from "react";
import FilterChip from "@/src/components/ui/atoms/filter-chip";
import { STATUS_LABEL, type OrderStatus, type OrderStatusFilter } from "../../utils/orders";

// Lifecycle order, so the chips read left to right the way an order moves.
const STATUSES: OrderStatus[] = ["DRAFT", "CONFIRMED", "PREPARING", "COMPLETED", "CANCELLED"];

const FILTERS: { value: OrderStatusFilter; label: string }[] = [
  { value: "all", label: "All" },
  ...STATUSES.map((status) => ({ value: status, label: STATUS_LABEL[status] })),
];

type StatusFilterProps = {
  value: OrderStatusFilter;
  onChange: (status: OrderStatusFilter) => void;
  counts: Record<OrderStatusFilter, number>;
};

export default function StatusFilter({ value, onChange, counts }: StatusFilterProps) {
  const pillId = useId();

  return (
    <div role="group" aria-label="Filter by status" className="isolate flex flex-wrap gap-2">
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
