import { UserRoundX } from "lucide-react";
import { Avatar } from "@/src/components/ui/atoms/avatar";
import type { AuditEntry } from "../../utils/audit";
import OutcomeBadge from "../atoms/outcome-badge";

// Mirrors StaffIdentity: the badge sits under the role on phones so long names
// keep the full width, and moves to the right edge once there is room.
export default function AuditActorIdentity({ entry }: { entry: AuditEntry }) {
  const { actor } = entry;

  return (
    <div className="flex items-start gap-4">
      {actor ? (
        <Avatar name={actor.name} className="size-12 text-lg" />
      ) : (
        <span aria-hidden="true" className="inline-flex size-12 shrink-0 items-center justify-center rounded-full bg-muted text-ink-muted">
          <UserRoundX className="size-5" strokeWidth={2.25} />
        </span>
      )}
      <div className="flex min-w-0 flex-1 flex-col gap-0.5 pt-0.5">
        <h3 className="text-lg leading-snug font-semibold text-balance break-words text-ink">
          {actor ? actor.name : "Unidentified actor"}
        </h3>
        <p className="text-sm break-all text-ink-muted">
          {actor ? (
            <>
              {actor.username}
              <span aria-hidden="true" className="mx-1.5">
                –
              </span>
              <span className="sr-only">, </span>
              {actor.role}
            </>
          ) : (
            "No one was signed in"
          )}
        </p>
        <div className="mt-2 sm:hidden">
          <OutcomeBadge outcome={entry.outcome} />
        </div>
      </div>
      <div className="hidden shrink-0 pt-1 sm:block">
        <OutcomeBadge outcome={entry.outcome} />
      </div>
    </div>
  );
}
