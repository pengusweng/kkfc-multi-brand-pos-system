import { Ban, Check } from "lucide-react";
import type { StaffStatus } from "../../utils/staff";

// Soft status badges (DESIGN.md › Status Badges): tinted fill, 1px matching
// border, dark ink text, always paired with an icon so color is never the only cue.
const STATUS_BADGE: Record<StaffStatus, { label: string; icon: typeof Check; className: string }> = {
  active: {
    label: "Active",
    icon: Check,
    className:
      "border-[#9ed2b0] bg-[#e3f4e9] text-[#166b3a] dark:border-[oklch(0.62_0.13_150/0.4)] dark:bg-[oklch(0.62_0.13_150/0.14)] dark:text-[oklch(0.84_0.11_150)]",
  },
  inactive: {
    label: "Inactive",
    icon: Ban,
    className: "border-hairline bg-muted text-ink-muted",
  },
};

export default function StatusBadge({ status }: { status: StaffStatus }) {
  const { label, icon: Icon, className } = STATUS_BADGE[status];
  return (
    <span
      className={`inline-flex h-6 items-center gap-1.5 rounded-full border px-2.5 text-xs font-semibold tracking-[0.02em] whitespace-nowrap ${className}`}
    >
      <Icon aria-hidden="true" className="size-3.5" strokeWidth={2.5} />
      {label}
    </span>
  );
}
