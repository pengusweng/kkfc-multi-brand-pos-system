import type { ReactNode } from "react";
import { DataTable, DataTableHead } from "@/src/components/ui/organisms/data-table";
import type { AuditEntry } from "../../utils/audit";
import { CLUSTER, COL, COLUMN_COUNT } from "../../utils/table-columns";
import AuditRow from "../molecules/audit-row";
import AuditSkeletonRow from "../molecules/audit-skeleton-row";

type AuditTableProps = {
  entries: AuditEntry[];
  onView?: (entry: AuditEntry) => void;
  loading?: boolean;
  skeletonRows?: number;
  emptyMessage?: string;
  footer?: ReactNode;
};

export default function AuditTable({
  entries,
  onView,
  loading = false,
  skeletonRows,
  emptyMessage = "No audit entries yet.",
  footer,
}: AuditTableProps) {
  return (
    <DataTable
      columnCount={COLUMN_COUNT}
      loading={loading}
      loadingLabel="Loading audit history…"
      skeletonRows={skeletonRows}
      skeletonRow={(i) => <AuditSkeletonRow index={i} />}
      emptyMessage={emptyMessage}
      footer={footer}
      head={
        <>
          <DataTableHead className={COL.time}>Time</DataTableHead>
          <DataTableHead className={`hidden md:table-cell ${COL.actor}`}>Actor</DataTableHead>
          <DataTableHead className={`${CLUSTER} hidden md:table-cell ${COL.action}`}>Action</DataTableHead>
          <DataTableHead className={`w-px ${COL.outcome}`}>Outcome</DataTableHead>
          <DataTableHead className={`w-px ${COL.view}`}>
            <span className="sr-only">Actions</span>
          </DataTableHead>
        </>
      }
      rows={entries.map((entry) => (
        <AuditRow key={entry.id} entry={entry} onView={onView} />
      ))}
    />
  );
}
