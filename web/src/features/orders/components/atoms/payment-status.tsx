import { CircleCheck, Clock, Undo2 } from "lucide-react";
import type { PaymentStatus as Payment } from "../../utils/orders";

// Payment reads as an ordinary cell: same size and ink as its neighbors. The
// state's color (DESIGN.md › Status Indicators) lives in the leading icon, so
// the column scans by color without the words turning into colored links.
const PAYMENT: Record<Payment, { label: string; icon: typeof Clock; tone: string }> = {
  PAID: {
    label: "Paid",
    icon: CircleCheck,
    tone: "text-[#1f7a45] dark:text-[oklch(0.76_0.13_150)]",
  },
  UNPAID: {
    label: "Unpaid",
    icon: Clock,
    tone: "text-[#8a6a00] dark:text-[oklch(0.82_0.13_85)]",
  },
  REFUNDED: {
    label: "Refunded",
    icon: Undo2,
    tone: "text-[#5a3ea6] dark:text-[oklch(0.76_0.11_290)]",
  },
};

export default function PaymentStatus({ payment }: { payment: Payment }) {
  const { label, icon: Icon, tone } = PAYMENT[payment];
  return (
    // Block-level flex: an inline-flex led by an icon takes the icon's bottom as
    // its baseline, which lifts the label off the row's text line.
    <span className="flex w-fit items-center gap-1.5 whitespace-nowrap text-ink">
      <Icon aria-hidden="true" className={`size-4 shrink-0 ${tone}`} strokeWidth={2.25} />
      {label}
    </span>
  );
}
