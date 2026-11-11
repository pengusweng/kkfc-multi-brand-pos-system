import { ChevronDown } from "lucide-react";
import { userRoleSchema, type UserRole } from "../../schemas/userSchema";
import { ROLE_LABEL } from "../../utils/staff";

type RoleSelectProps = {
  /** Undefined means every role. */
  value: UserRole | undefined;
  onChange: (role: UserRole | undefined) => void;
};

// Native select: keyboard, screen reader and mobile pickers come for free.
export default function RoleSelect({ value, onChange }: RoleSelectProps) {
  return (
    <div className="relative w-full sm:w-48 sm:shrink-0">
      <select
        value={value ?? ""}
        onChange={(e) => onChange(e.target.value ? userRoleSchema.parse(e.target.value) : undefined)}
        aria-label="Filter by role"
        className="h-10 w-full cursor-pointer appearance-none rounded-lg border border-hairline bg-field pr-9 pl-3 text-base text-ink outline-none focus-visible:border-primary focus-visible:ring-2 focus-visible:ring-primary/15 md:text-sm"
      >
        <option value="">All roles</option>
        {userRoleSchema.options.map((role) => (
          <option key={role} value={role}>
            {ROLE_LABEL[role]}
          </option>
        ))}
      </select>
      <ChevronDown
        aria-hidden="true"
        className="pointer-events-none absolute top-1/2 right-3 size-4 -translate-y-1/2 text-ink-muted"
      />
    </div>
  );
}
