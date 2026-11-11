import type { ReactNode } from "react";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import type { StaffMember, StaffSort, StaffSortField } from "../../utils/staff";
import { CLUSTER, COL, COLUMN_COUNT, HEAD } from "../../utils/table-columns";
import SortableHead from "../molecules/sortable-head";
import StaffRow from "../molecules/staff-row";
import StaffSkeletonRow from "../molecules/staff-skeleton-row";

type StaffTableProps = {
  staff: StaffMember[];
  onView: (member: StaffMember) => void;
  sort: StaffSort;
  onSort: (field: StaffSortField) => void;
  loading?: boolean;
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
  skeletonRows = 8,
  emptyMessage = "No staff accounts yet.",
  footer,
}: StaffTableProps) {
  return (
    <div className="mt-4 overflow-hidden rounded-xl border border-hairline bg-card">
      {loading ? (
        <p className="sr-only" role="status">
          Loading staff accounts…
        </p>
      ) : null}
      <Table className="xl:table-fixed" aria-busy={loading}>
        <TableHeader>
          <TableRow className="border-hairline bg-surface-hover hover:bg-surface-hover">
            <SortableHead field="name" label="Name" sort={sort} onSort={onSort} className={`${HEAD} ${COL.name}`} />
            <SortableHead
              field="username"
              label="Username"
              sort={sort}
              onSort={onSort}
              className={`${HEAD} hidden md:table-cell ${COL.username}`}
            />
            <SortableHead
              field="role"
              label="Role"
              sort={sort}
              onSort={onSort}
              className={`${HEAD} ${CLUSTER} hidden md:table-cell ${COL.role}`}
            />
            <SortableHead field="status" label="Status" sort={sort} onSort={onSort} className={`${HEAD} w-px ${COL.status}`} />
            <TableHead className={`${HEAD} w-px ${COL.view}`}>
              <span className="sr-only">Actions</span>
            </TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {loading ? (
            Array.from({ length: skeletonRows }, (_, i) => <StaffSkeletonRow key={i} index={i} />)
          ) : staff.length === 0 ? (
            <TableRow className="hover:bg-transparent">
              <TableCell colSpan={COLUMN_COUNT} className="px-4 py-10 text-center text-ink-muted">
                {emptyMessage}
              </TableCell>
            </TableRow>
          ) : (
            staff.map((member) => <StaffRow key={member.id} member={member} onView={onView} />)
          )}
        </TableBody>
      </Table>
      {footer}
    </div>
  );
}
