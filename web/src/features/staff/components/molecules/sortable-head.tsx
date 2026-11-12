import { ArrowDown, ArrowUp, ChevronsUpDown } from "lucide-react";
import { DataTableHead } from "@/src/components/ui/organisms/data-table";
import type { StaffSort, StaffSortField } from "../../utils/staff";

type SortableHeadProps = {
  field: StaffSortField;
  label: string;
  sort: StaffSort;
  onSort: (field: StaffSortField) => void;
  className?: string;
};

// A column header that sorts the list. The faint double chevron says "sortable";
// the active column turns full ink with a solid arrow for its direction.
export default function SortableHead({ field, label, sort, onSort, className = "" }: SortableHeadProps) {
  const active = sort?.by === field ? sort.order : null;
  const Icon = active === "asc" ? ArrowUp : active === "desc" ? ArrowDown : ChevronsUpDown;

  return (
    <DataTableHead
      aria-sort={active === "asc" ? "ascending" : active === "desc" ? "descending" : "none"}
      className={className}
    >
      <button
        type="button"
        onClick={() => onSort(field)}
        className={`group -ml-2 inline-flex h-8 cursor-pointer items-center gap-1.5 rounded-md px-2 transition-colors outline-none hover:bg-ink/6 hover:text-ink focus-visible:ring-2 focus-visible:ring-primary/40 ${
          active ? "text-ink" : ""
        }`}
      >
        {label}
        <Icon
          aria-hidden="true"
          strokeWidth={2.25}
          className={`size-3.5 shrink-0 transition-opacity ${active ? "opacity-100" : "opacity-40 group-hover:opacity-80"}`}
        />
      </button>
    </DataTableHead>
  );
}
