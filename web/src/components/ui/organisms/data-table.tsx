import { Children, Fragment, type ComponentProps, type ReactNode } from "react";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";

const HEAD = "h-11 px-3 md:px-4 text-[0.8125rem] font-semibold tracking-[0.02em] text-ink-muted";

// Header cell with the shared data-table type treatment. Column-specific classes (widths, responsive hiding) go in className.
export function DataTableHead({ className = "", ...props }: ComponentProps<typeof TableHead>) {
  return <TableHead className={`${HEAD} ${className}`} {...props} />;
}

type DataTableProps = {
  /** Header cells (DataTableHead or anything rendering one). */
  head: ReactNode;
  /** Body rows. When there are none, the empty message is shown. */
  rows: ReactNode;
  columnCount: number;
  loading?: boolean;
  loadingLabel?: string;
  skeletonRow: (index: number) => ReactNode;
  skeletonRows?: number;
  emptyMessage?: ReactNode;
  footer?: ReactNode;
};

export function DataTable({
  head,
  rows,
  columnCount,
  loading = false,
  loadingLabel = "Loading…",
  skeletonRow,
  skeletonRows = 8,
  emptyMessage = "Nothing here yet.",
  footer,
}: DataTableProps) {
  return (
    <div className="mt-4 overflow-hidden rounded-xl border border-hairline bg-card">
      {loading ? (
        <p className="sr-only" role="status">
          {loadingLabel}
        </p>
      ) : null}
      <Table className="xl:table-fixed" aria-busy={loading}>
        <TableHeader>
          <TableRow className="border-hairline bg-surface-hover hover:bg-surface-hover">{head}</TableRow>
        </TableHeader>
        <TableBody>
          {loading ? (
            Array.from({ length: skeletonRows }, (_, i) => <Fragment key={i}>{skeletonRow(i)}</Fragment>)
          ) : Children.count(rows) === 0 ? (
            <TableRow className="hover:bg-transparent">
              <TableCell colSpan={columnCount} className="px-4 py-10 text-center text-ink-muted">
                {emptyMessage}
              </TableCell>
            </TableRow>
          ) : (
            rows
          )}
        </TableBody>
      </Table>
      {footer}
    </div>
  );
}
