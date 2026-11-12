import type { ReactNode } from "react";
import { DataTable, DataTableHead } from "@/src/components/ui/organisms/data-table";
import type { StaffMember, StaffSort, StaffSortField } from "../../utils/staff";
import { CLUSTER, COL, COLUMN_COUNT } from "../../utils/table-columns";
import SortableHead from "../molecules/sortable-head";
import StaffRow from "../molecules/staff-row";
import StaffSkeletonRow from "../molecules/staff-skeleton-row";

type StaffTableProps = {
  staff: StaffMember[];
  onView: (member: StaffMember) => void;
  sort: StaffSort;
  onSort: (field: StaffSortField) => void;
  loading?: boolean;
  refreshing?: boolean;
  skeletonRows?: number;
  emptyMessage?: string;
  footer?: ReactNode;
};

export default function StaffTable({
  staff,
  onView,
  sort,
  onSort,
  loading = false,
  refreshing = false,
  skeletonRows,
  emptyMessage = "No staff accounts yet.",
  footer,
}: StaffTableProps) {
  return (
    <DataTable
      columnCount={COLUMN_COUNT}
      loading={loading}
      refreshing={refreshing}
      loadingLabel="Loading staff accounts…"
      skeletonRows={skeletonRows}
      skeletonRow={(i) => <StaffSkeletonRow index={i} />}
      emptyMessage={emptyMessage}
      footer={footer}
      head={
        <>
          <SortableHead field="name" label="Name" sort={sort} onSort={onSort} className={COL.name} />
          <SortableHead
            field="username"
            label="Username"
            sort={sort}
            onSort={onSort}
            className={`hidden md:table-cell ${COL.username}`}
          />
          <SortableHead
            field="role"
            label="Role"
            sort={sort}
            onSort={onSort}
            className={`${CLUSTER} hidden md:table-cell ${COL.role}`}
          />
          <SortableHead field="status" label="Status" sort={sort} onSort={onSort} className={`w-px ${COL.status}`} />
          <DataTableHead className={`w-px ${COL.view}`}>
            <span className="sr-only">Actions</span>
          </DataTableHead>
        </>
      }
      rows={staff.map((member) => (
        <StaffRow key={member.id} member={member} onView={onView} />
      ))}
    />
  );
}
