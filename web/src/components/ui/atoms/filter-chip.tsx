type FilterChipProps = {
  label: string;
  count: number;
  selected: boolean;
  onClick: () => void;
};

export default function FilterChip({ label, count, selected, onClick }: FilterChipProps) {
  return (
    <button
      type="button"
      aria-pressed={selected}
      onClick={onClick}
      className={`inline-flex h-10 cursor-pointer items-center gap-2 rounded-full border px-3.5 text-sm font-semibold transition-colors outline-none focus-visible:ring-2 focus-visible:ring-primary/40 ${
        selected ? "border-ink bg-ink text-card" : "border-hairline bg-card text-ink hover:bg-surface-hover"
      }`}
    >
      {label}
      <span
        className={`inline-flex h-5 min-w-5 items-center justify-center rounded-full px-1.5 text-xs font-semibold tabular-nums ${
          selected ? "bg-card/15 text-card" : "bg-surface-hover text-ink-muted"
        }`}
      >
        {count}
      </span>
    </button>
  );
}
