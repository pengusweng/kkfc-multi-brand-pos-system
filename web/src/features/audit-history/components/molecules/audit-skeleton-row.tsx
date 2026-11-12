import { TableCell, TableRow } from "@/components/ui/table";
import SkeletonBar from "@/src/components/ui/atoms/skeleton-bar";
import { CLUSTER } from "../../utils/table-columns";

// Varied widths so a stack of rows reads as a list, not a grid.
const WIDTHS = [
  { actor: "w-32", action: "w-40" },
  { actor: "w-28", action: "w-32" },
  { actor: "w-36", action: "w-44" },
  { actor: "w-24", action: "w-36" },
];

export default function AuditSkeletonRow({ index }: { index: number }) {
  const w = WIDTHS[index % WIDTHS.length];
  return (
    <TableRow aria-hidden="true" className="border-hairline hover:bg-transparent motion-safe:animate-pulse">
      <TableCell className="px-3 py-3 md:px-4">
        <div className="flex flex-col gap-0.5">
          <SkeletonBar className="w-36" />
          <SkeletonBar className={`${w.actor} md:hidden`} />
          <SkeletonBar className={`${w.action} md:hidden`} />
        </div>
      </TableCell>
      <TableCell className="hidden px-4 py-3 md:table-cell">
        <SkeletonBar className={w.actor} />
      </TableCell>
      <TableCell className={`hidden px-4 py-3 md:table-cell ${CLUSTER}`}>
        <SkeletonBar className={w.action} />
      </TableCell>
      <TableCell className="px-3 py-3 md:px-4">
        <span className="block h-6 w-20 rounded-full bg-ink/8" />
      </TableCell>
      <TableCell className="py-3 pr-1.5 pl-1 md:pr-2 md:pl-4">
        <span className="ml-auto block h-8 w-16 rounded-md bg-ink/8" />
      </TableCell>
    </TableRow>
  );
}
