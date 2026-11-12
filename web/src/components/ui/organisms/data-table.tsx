import { Children, Fragment, isValidElement, type ComponentProps, type ReactNode } from "react";
import { cn } from "cn";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";

const HEAD = "h-11 px-3 md:px-4 text-[0.8125rem] font-semibold tracking-[0.02em] text-ink-muted";

// Header cell with the shared data-table type treatment. Column-specific classes (widths, responsive hiding) go in className.
export function DataTableHead({ className = "", ...props }: ComponentProps<typeof TableHead>) {
  return <TableHead className={`${HEAD} ${className}`} {...props} />;
}

type DataTableProps = {
  /** Header cells (DataTableHead or anything rendering one). */
  head: ReactNode;
  /** Body rows, each with a stable key. When there are none, the empty message is shown. */
  rows: ReactNode;
  columnCount: number;
  /** First load, nothing to show yet: skeleton rows. */
  loading?: boolean;
  /** New rows are on their way but the current ones are still worth reading (a filter or page change). */
  refreshing?: boolean;
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
  refreshing = false,
  loadingLabel = "Loading…",
  skeletonRow,
  skeletonRows = 8,
  emptyMessage = "Nothing here yet.",
  footer,
}: DataTableProps) {
  const rowList = Children.toArray(rows);
  // Identifies what the body shows. When it changes the body remounts and the
  // new rows cascade in (.rows-in); an identical refetch keeps the same key and
  // stays still.
  const bodyKey = loading
    ? "loading"
    : rowList.length === 0
      ? `empty:${typeof emptyMessage === "string" ? emptyMessage : ""}`
      : rowList.map((row) => (isValidElement(row) ? row.key : "")).join("|");

  return (
    <div className="mt-4 overflow-hidden rounded-xl border border-hairline bg-card">
      {loading || refreshing ? (
        <p className="sr-only" role="status">
          {loadingLabel}
        </p>
      ) : null}
      <Table className="xl:table-fixed" aria-busy={loading || refreshing}>
        <TableHeader>
          <TableRow className="border-hairline bg-surface-hover hover:bg-surface-hover">{head}</TableRow>
        </TableHeader>
        <TableBody
          key={bodyKey}
          className={cn(
            "transition-opacity duration-200 ease-out",
            // Skeletons keep their own pulse; only real rows cascade in.
            !loading && "rows-in",
            // Stale rows dim only if the wait is noticeable, so a fast response
            // goes straight from old rows to new without a flicker in between.
            refreshing && "opacity-55 delay-150",
          )}
        >
          {loading ? (
            Array.from({ length: skeletonRows }, (_, i) => <Fragment key={i}>{skeletonRow(i)}</Fragment>)
          ) : rowList.length === 0 ? (
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
