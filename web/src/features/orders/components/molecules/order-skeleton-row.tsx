import { TableCell, TableRow } from "@/components/ui/table";
import SkeletonBar from "@/src/components/ui/atoms/skeleton-bar";
import { CLUSTER } from "../../utils/table-columns";

// Varied widths so a stack of rows reads as a list, not a grid.
const WIDTHS = [
  { brand: "w-28", channel: "w-16" },
  { brand: "w-32", channel: "w-20" },
  { brand: "w-24", channel: "w-16" },
  { brand: "w-36", channel: "w-20" },
];

export default function OrderSkeletonRow({ index }: { index: number }) {
  const w = WIDTHS[index % WIDTHS.length];
  return (
    <TableRow aria-hidden="true" className="border-hairline hover:bg-transparent motion-safe:animate-pulse">
      <TableCell className="px-3 py-3 md:px-4">
        <div className="flex flex-col gap-0.5">
          <SkeletonBar className="w-20" />
          <SkeletonBar className="w-40 md:hidden" />
          <SkeletonBar className={`${w.brand} md:hidden`} />
        </div>
      </TableCell>
      <TableCell className="hidden px-4 py-3 md:table-cell">
        <SkeletonBar className="w-40" />
      </TableCell>
      <TableCell className="hidden px-4 py-3 md:table-cell">
        <SkeletonBar className={w.brand} />
      </TableCell>
      <TableCell className={`hidden px-4 py-3 md:table-cell ${CLUSTER}`}>
        <SkeletonBar className={w.channel} />
      </TableCell>
      <TableCell className="px-3 py-3 md:px-4">
        <span className="block h-6 w-24 rounded-full bg-ink/8" />
      </TableCell>
      <TableCell className="hidden px-4 py-3 md:table-cell">
        <SkeletonBar className="w-12" />
      </TableCell>
      <TableCell className="py-3 pr-1.5 pl-1 md:pr-2 md:pl-4">
        <span className="ml-auto block h-8 w-16 rounded-md bg-ink/8" />
      </TableCell>
    </TableRow>
  );
}
