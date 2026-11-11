import type { ReactNode } from "react";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import type { StaffMember } from "../../utils/staff";
import { CLUSTER, COL, COLUMN_COUNT, HEAD } from "../../utils/table-columns";
import StaffRow from "../molecules/staff-row";
import StaffSkeletonRow from "../molecules/staff-skeleton-row";

type StaffTableProps = {
  staff: StaffMember[];
  loading?: boolean;
  skeletonRows?: number;
  emptyMessage?: string;
  footer?: ReactNode;
};

export default function StaffTable({
  staff,
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
            <TableHead className={`${HEAD} ${COL.name}`}>Name</TableHead>
            <TableHead className={`${HEAD} hidden md:table-cell ${COL.username}`}>Username</TableHead>
            <TableHead className={`${HEAD} ${CLUSTER} hidden md:table-cell ${COL.role}`}>Role</TableHead>
            <TableHead className={`${HEAD} w-px ${COL.status}`}>Status</TableHead>
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
            staff.map((member) => <StaffRow key={member.id} member={member} />)
          )}
        </TableBody>
      </Table>
      {footer}
    </div>
  );
}
