import { TableCell, TableRow } from "@/components/ui/table";
import { CLUSTER } from "../../utils/table-columns";
import SkeletonBar from "../atoms/skeleton-bar";

// Varied widths so a stack of rows reads as a list of names, not a grid.
const WIDTHS = [
  { name: "w-40", username: "w-28", role: "w-20" },
  { name: "w-32", username: "w-24", role: "w-24" },
  { name: "w-48", username: "w-32", role: "w-16" },
  { name: "w-36", username: "w-20", role: "w-24" },
];

export default function StaffSkeletonRow({ index }: { index: number }) {
  const w = WIDTHS[index % WIDTHS.length];
  return (
    <TableRow aria-hidden="true" className="border-hairline hover:bg-transparent motion-safe:animate-pulse">
      <TableCell className="px-3 py-3 md:px-4">
        <div className="flex flex-col gap-0.5">
          <SkeletonBar className={w.name} />
          <SkeletonBar className={`${w.username} md:hidden`} />
          <SkeletonBar className={`${w.role} md:hidden`} />
        </div>
      </TableCell>
      <TableCell className="hidden px-4 py-3 md:table-cell">
        <SkeletonBar className={w.username} />
      </TableCell>
      <TableCell className={`hidden px-4 py-3 md:table-cell ${CLUSTER}`}>
        <SkeletonBar className={w.role} />
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
