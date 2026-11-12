import { Ban, Check, TriangleAlert } from "lucide-react";
import type { AuditOutcome } from "../../utils/audit";

// Soft status badges (DESIGN.md › Status Badges): tinted fill, 1px matching
// border, dark ink text, always paired with an icon so color is never the only cue.
const OUTCOME_BADGE: Record<AuditOutcome, { label: string; icon: typeof Check; className: string }> = {
  success: {
    label: "Success",
    icon: Check,
    className:
      "border-[#9ed2b0] bg-[#e3f4e9] text-[#166b3a] dark:border-[oklch(0.62_0.13_150/0.4)] dark:bg-[oklch(0.62_0.13_150/0.14)] dark:text-[oklch(0.84_0.11_150)]",
  },
  denied: {
    label: "Denied",
    icon: Ban,
    className:
      "border-[#f0c987] bg-[#fdf1dc] text-[#7a4a00] dark:border-[oklch(0.75_0.14_75/0.4)] dark:bg-[oklch(0.75_0.14_75/0.14)] dark:text-[oklch(0.86_0.11_80)]",
  },
  fail: {
    label: "Failed",
    icon: TriangleAlert,
    className:
      "border-[#edb3ae] bg-[#fbe6e4] text-[#a1231b] dark:border-[oklch(0.6_0.19_27/0.45)] dark:bg-[oklch(0.6_0.19_27/0.15)] dark:text-[oklch(0.82_0.1_27)]",
  },
};

export default function OutcomeBadge({ outcome }: { outcome: AuditOutcome }) {
  const { label, icon: Icon, className } = OUTCOME_BADGE[outcome];
  return (
    <span
      className={`inline-flex h-6 items-center gap-1.5 rounded-full border px-2.5 text-xs font-semibold tracking-[0.02em] whitespace-nowrap ${className}`}
    >
      <Icon aria-hidden="true" className="size-3.5" strokeWidth={2.5} />
      {label}
    </span>
  );
}
