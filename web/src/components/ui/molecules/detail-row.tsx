import type { ReactNode } from "react";

// One label/value pair inside a <dl>; rows are separated by hairlines.
export default function DetailRow({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div className="grid grid-cols-[7.5rem_minmax(0,1fr)] items-baseline gap-x-4 border-t border-hairline py-3 sm:grid-cols-[9rem_minmax(0,1fr)]">
      <dt className="text-[0.8125rem] font-semibold tracking-[0.02em] text-ink-muted">{label}</dt>
      <dd className="text-sm text-ink">{children}</dd>
    </div>
  );
}
