"use client";

import { motion, useReducedMotion } from "framer-motion";
import { cn } from "cn";

type FilterChipProps = {
  label: string;
  count: number;
  selected: boolean;
  onClick: () => void;
  /** Shared by the chips of one group, so the selected pill slides between them. */
  pillId: string;
};

// The selected chip's ink pill is one shared layout element: picking another
// chip slides it across instead of blinking one chip off and another on.
// The chip group must be `isolate` so the pill's negative z-index stays inside it.
const SLIDE = { type: "spring", duration: 0.32, bounce: 0.12 } as const;

export default function FilterChip({ label, count, selected, onClick, pillId }: FilterChipProps) {
  const reduceMotion = useReducedMotion();

  return (
    <button
      type="button"
      aria-pressed={selected}
      onClick={onClick}
      className={cn(
        "relative inline-flex h-10 cursor-pointer items-center gap-2 rounded-full border px-3.5 text-sm font-semibold outline-none focus-visible:ring-2 focus-visible:ring-primary/40",
        // No fill of their own: the chips sit on the card, so the sliding pill can pass beneath them.
        selected ? "border-transparent text-card" : "border-hairline text-ink hover:bg-surface-hover",
        "transition-[color,background-color,border-color] duration-200",
      )}
    >
      {selected ? (
        <motion.span
          layoutId={pillId}
          transition={reduceMotion ? { duration: 0 } : SLIDE}
          aria-hidden="true"
          // Behind every label in the group (the group isolates), so it slides under its neighbours, never over.
          className="absolute -inset-px -z-10 rounded-full bg-ink"
        />
      ) : null}
      <span className="relative">{label}</span>
      <span
        className={cn(
          "relative inline-flex h-5 min-w-5 items-center justify-center rounded-full px-1.5 text-xs font-semibold tabular-nums transition-colors duration-200",
          selected ? "bg-card/15 text-card" : "bg-surface-hover text-ink-muted",
        )}
      >
        {count}
      </span>
    </button>
  );
}
