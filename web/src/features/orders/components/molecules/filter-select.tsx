import { ChevronDown } from "lucide-react";

type FilterSelectProps<T extends string> = {
  /** Accessible name, e.g. "Filter by brand". */
  label: string;
  /** The empty option, e.g. "All brands". */
  allLabel: string;
  options: { value: T; label: string }[];
  /** Undefined means no filter. */
  value: T | undefined;
  onChange: (value: T | undefined) => void;
  className?: string;
};

// Native select, like the audit action filter: keyboard, screen reader and
// mobile pickers come for free.
export default function FilterSelect<T extends string>({
  label,
  allLabel,
  options,
  value,
  onChange,
  className = "sm:w-48",
}: FilterSelectProps<T>) {
  return (
    <div className={`relative w-full sm:shrink-0 ${className}`}>
      <select
        value={value ?? ""}
        onChange={(e) => onChange((e.target.value || undefined) as T | undefined)}
        aria-label={label}
        className="h-10 w-full cursor-pointer appearance-none truncate rounded-lg border border-hairline bg-field pr-9 pl-3 text-base text-ink outline-none focus-visible:border-primary focus-visible:ring-2 focus-visible:ring-primary/15 md:text-sm"
      >
        <option value="">{allLabel}</option>
        {options.map((option) => (
          <option key={option.value} value={option.value}>
            {option.label}
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
