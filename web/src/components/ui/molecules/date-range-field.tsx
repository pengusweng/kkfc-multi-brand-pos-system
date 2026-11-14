import { X } from "lucide-react";

type DateRange = { from?: string; to?: string };

type DateRangeFieldProps = {
  value: DateRange;
  onChange: (range: DateRange) => void;
  /** Latest selectable date (YYYY-MM-DD), normally today. Undefined leaves it open. */
  max?: string;
};

// Native date inputs open the platform calendar, keep keyboard entry, and
// follow the theme's color-scheme for the picker. Empty inputs read muted so
// the "mm/dd/yyyy" hint doesn't look like a chosen date.
const INPUT =
  "h-10 min-w-0 flex-1 cursor-pointer rounded-lg border border-hairline bg-field px-2.5 text-base text-ink outline-none focus-visible:border-primary focus-visible:ring-2 focus-visible:ring-primary/15 data-[empty=true]:text-ink-muted sm:w-40 sm:flex-none sm:px-3 md:text-sm [&::-webkit-calendar-picker-indicator]:cursor-pointer [&::-webkit-calendar-picker-indicator]:opacity-60 [&::-webkit-calendar-picker-indicator]:hover:opacity-100";

export default function DateRangeField({ value, onChange, max }: DateRangeFieldProps) {
  const { from, to } = value;

  return (
    <div role="group" aria-label="Filter by date" className="flex w-full items-center gap-2 sm:w-auto">
      <input
        type="date"
        aria-label="From date"
        value={from ?? ""}
        max={to ?? max}
        data-empty={!from}
        // Picking a start after the end moves the end along, so the range never inverts.
        onChange={(e) => {
          const next = e.target.value || undefined;
          onChange({ from: next, to: next && to && next > to ? next : to });
        }}
        className={INPUT}
      />
      <span aria-hidden="true" className="shrink-0 text-sm text-ink-muted">
        to
      </span>
      <input
        type="date"
        aria-label="To date"
        value={to ?? ""}
        min={from}
        max={max}
        data-empty={!to}
        onChange={(e) => {
          const next = e.target.value || undefined;
          onChange({ from: next && from && next < from ? next : from, to: next });
        }}
        className={INPUT}
      />
      {from || to ? (
        <button
          type="button"
          onClick={() => onChange({})}
          aria-label="Clear dates"
          // Phones are too narrow for it; "Clear filters" below covers them.
          className="hidden size-8 shrink-0 cursor-pointer place-items-center rounded-md text-ink-muted outline-none hover:bg-ink/6 hover:text-ink focus-visible:ring-2 focus-visible:ring-primary/40 sm:grid motion-safe:animate-in motion-safe:fade-in-0 motion-safe:zoom-in-90 motion-safe:duration-150"
        >
          <X aria-hidden="true" className="size-4" />
        </button>
      ) : null}
    </div>
  );
}
