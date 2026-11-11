import { TableCell, TableRow } from "@/components/ui/table";
import type { StaffMember } from "../../utils/staff";
import { CLUSTER } from "../../utils/table-columns";
import StatusBadge from "../atoms/status-badge";
import ViewButton from "../atoms/view-button";

type StaffRowProps = {
  member: StaffMember;
  onView: (member: StaffMember) => void;
};

export default function StaffRow({ member, onView }: StaffRowProps) {
  return (
    <TableRow className="border-hairline hover:bg-surface-hover/50">
      <TableCell className="px-3 py-3 whitespace-normal md:px-4 md:whitespace-nowrap xl:whitespace-normal">
        <div className="flex flex-col gap-0.5">
          <span className="font-semibold text-ink">{member.name}</span>
          {/* Narrow screens drop the Username and Role columns; both ride along here instead. */}
          <span className="text-ink-muted md:hidden">{member.username}</span>
          <span className="text-ink-muted md:hidden">{member.role}</span>
        </div>
      </TableCell>
      <TableCell className="hidden px-4 py-3 text-ink-muted md:table-cell xl:break-all xl:whitespace-normal">
        {member.username}
      </TableCell>
      <TableCell className={`hidden px-4 py-3 text-ink md:table-cell xl:whitespace-normal ${CLUSTER}`}>
        {member.role}
      </TableCell>
      <TableCell className="px-3 py-3 md:px-4">
        <StatusBadge status={member.status} />
      </TableCell>
      <TableCell className="py-3 pr-1.5 pl-1 text-right md:pr-2 md:pl-4">
        <ViewButton label={`View ${member.name}`} onClick={() => onView(member)} />
      </TableCell>
    </TableRow>
  );
}
