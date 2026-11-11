import { Avatar } from "@/src/components/ui/atoms/avatar";
import type { StaffMember } from "../../utils/staff";
import StatusBadge from "../atoms/status-badge";

// The badge sits under the username on phones so long names keep the full
// width, and moves to the right edge once there is room beside the name.
export default function StaffIdentity({ member }: { member: StaffMember }) {
  return (
    <div className="flex items-start gap-4">
      <Avatar name={member.name} className="size-12 text-lg" />
      <div className="flex min-w-0 flex-1 flex-col gap-0.5 pt-0.5">
        <h3 className="text-lg leading-snug font-semibold text-balance break-words text-ink">{member.name}</h3>
        <p className="text-sm break-all text-ink-muted">{member.username}</p>
        <div className="mt-2 sm:hidden">
          <StatusBadge status={member.status} />
        </div>
      </div>
      <div className="hidden shrink-0 pt-1 sm:block">
        <StatusBadge status={member.status} />
      </div>
    </div>
  );
}
