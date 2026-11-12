import { ChevronDown } from "lucide-react";
import { ACTION_OPTIONS } from "../../utils/audit";

type ActionSelectProps = {
  /** Undefined means every action. */
  value: string | undefined;
  onChange: (action: string | undefined) => void;
};

// Native select, like the staff role filter: keyboard, screen reader and
// mobile pickers come for free, and optgroups keep 40+ actions scannable.
export default function ActionSelect({ value, onChange }: ActionSelectProps) {
  return (
    <div className="relative w-full sm:w-60 sm:shrink-0">
      <select
        value={value ?? ""}
        onChange={(e) => onChange(e.target.value || undefined)}
        aria-label="Filter by action"
        className="h-10 w-full cursor-pointer appearance-none truncate rounded-lg border border-hairline bg-field pr-9 pl-3 text-base text-ink outline-none focus-visible:border-primary focus-visible:ring-2 focus-visible:ring-primary/15 md:text-sm"
      >
        <option value="">All actions</option>
        {ACTION_OPTIONS.map((group) => (
          <optgroup key={group.label} label={group.label}>
            {group.actions.map((action) => (
              <option key={action.code} value={action.code}>
                {action.label}
              </option>
            ))}
          </optgroup>
        ))}
      </select>
      <ChevronDown
        aria-hidden="true"
        className="pointer-events-none absolute top-1/2 right-3 size-4 -translate-y-1/2 text-ink-muted"
      />
    </div>
  );
}
