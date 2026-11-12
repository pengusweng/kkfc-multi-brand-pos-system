import { TableCell, TableRow } from "@/components/ui/table";
import ViewButton from "@/src/components/ui/atoms/view-button";
import { formatAuditTime, type AuditEntry } from "../../utils/audit";
import { CLUSTER } from "../../utils/table-columns";
import OutcomeBadge from "../atoms/outcome-badge";

type AuditRowProps = {
  entry: AuditEntry;
  onView?: (entry: AuditEntry) => void;
};

export default function AuditRow({ entry, onView }: AuditRowProps) {
  return (
    <TableRow className="border-hairline hover:bg-surface-hover/50">
      <TableCell className="px-3 py-3 whitespace-normal md:px-4 md:whitespace-nowrap xl:whitespace-normal">
        <div className="flex flex-col gap-0.5">
          <time dateTime={entry.time} className="text-ink tabular-nums">
            {formatAuditTime(entry.time)}
          </time>
          {/* Narrow screens drop the Actor and Action columns; both ride along here instead. */}
          <span className="font-semibold text-ink md:hidden">{entry.actor}</span>
          <span className="text-ink-muted md:hidden">{entry.action}</span>
        </div>
      </TableCell>
      <TableCell className="hidden px-4 py-3 font-semibold text-ink md:table-cell xl:whitespace-normal">
        {entry.actor}
      </TableCell>
      <TableCell className={`hidden px-4 py-3 text-ink-muted md:table-cell xl:whitespace-normal ${CLUSTER}`}>
        {entry.action}
      </TableCell>
      <TableCell className="px-3 py-3 md:px-4">
        <OutcomeBadge outcome={entry.outcome} />
      </TableCell>
      <TableCell className="py-3 pr-1.5 pl-1 text-right md:pr-2 md:pl-4">
        <ViewButton label={`View ${entry.action} by ${entry.actor}`} onClick={() => onView?.(entry)} />
      </TableCell>
    </TableRow>
  );
}
