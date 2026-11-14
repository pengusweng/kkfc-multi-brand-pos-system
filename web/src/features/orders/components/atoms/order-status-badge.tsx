import type { OrderStatus } from "../../utils/orders";

// Every status is the same pill so the column reads as one list. Color is
// spent on orders that are still moving: Confirmed and Preparing get a tinted
// fill; Draft, Completed and Cancelled are only outlined, told apart by their
// dot (hollow for a draft that isn't committed yet).
const OUTLINE = "border-ink-muted/30 text-ink-muted";

const STATUS: Record<OrderStatus, { label: string; pill: string; dot: string; live?: boolean }> = {
  DRAFT: {
    label: "Draft",
    pill: OUTLINE,
    dot: "ring-1 ring-current ring-inset",
  },
  CONFIRMED: {
    label: "Confirmed",
    pill: "border-[#c3ccd9] bg-[#eef1f6] text-[#33445c] dark:border-[oklch(0.72_0.03_255/0.35)] dark:bg-[oklch(0.72_0.03_255/0.12)] dark:text-[oklch(0.88_0.02_255)]",
    dot: "bg-current",
  },
  PREPARING: {
    label: "Preparing",
    pill: "border-[#a5c6e8] bg-[#e6f0fa] text-[#1b5a96] dark:border-[oklch(0.62_0.12_250/0.4)] dark:bg-[oklch(0.62_0.12_250/0.14)] dark:text-[oklch(0.84_0.08_250)]",
    dot: "bg-current",
    live: true,
  },
  COMPLETED: {
    label: "Completed",
    pill: OUTLINE,
    dot: "bg-[#2e8a52] dark:bg-[oklch(0.72_0.13_150)]",
  },
  CANCELLED: {
    label: "Cancelled",
    pill: OUTLINE,
    dot: "bg-[#c2372e] dark:bg-[oklch(0.68_0.17_27)]",
  },
};

export default function OrderStatusBadge({ status }: { status: OrderStatus }) {
  const { label, pill, dot, live } = STATUS[status];
  return (
    <span
      className={`inline-flex h-6 items-center gap-1.5 rounded-full border px-2.5 text-[0.8125rem] font-semibold whitespace-nowrap ${pill}`}
    >
      <span aria-hidden="true" className="relative flex size-1.5">
        {/* Preparing breathes slowly: the one state where something is happening right now. */}
        {live ? (
          <span className="absolute inset-0 rounded-full bg-current opacity-50 motion-safe:animate-ping motion-safe:[animation-duration:1.8s]" />
        ) : null}
        <span className={`relative size-1.5 rounded-full ${dot}`} />
      </span>
      {label}
    </span>
  );
}
