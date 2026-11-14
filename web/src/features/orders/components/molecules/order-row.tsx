import { TableCell, TableRow } from "@/components/ui/table";
import ViewButton from "@/src/components/ui/atoms/view-button";
import { CHANNEL_LABEL, formatOrderTime, type OrderSummary } from "../../utils/orders";
import { CLUSTER } from "../../utils/table-columns";
import OrderStatusBadge from "../atoms/order-status-badge";
import PaymentStatus from "../atoms/payment-status";

type OrderRowProps = {
  order: OrderSummary;
  onView?: (order: OrderSummary) => void;
};

export default function OrderRow({ order, onView }: OrderRowProps) {
  const channel = CHANNEL_LABEL[order.channel];
  const placed = formatOrderTime(order.placedAt);
  const placedLabel = (
    <>
      {placed.date}, <span className="whitespace-nowrap">{placed.time}</span>
    </>
  );
  return (
    <TableRow className="border-hairline hover:bg-surface-hover/50">
      <TableCell className="px-3 py-3 whitespace-normal md:px-4 md:whitespace-nowrap xl:whitespace-normal">
        <div className="flex flex-col gap-0.5">
          <span className="font-semibold text-ink tabular-nums slashed-zero">{order.code}</span>
          {/* Narrow screens drop the Date, Brand and Channel columns; they ride along here instead. */}
          <time dateTime={order.placedAt} className="text-ink-muted md:hidden">
            {placedLabel}
          </time>
          <span className="text-ink-muted md:hidden">
            {order.brand} · <span className="whitespace-nowrap">{channel}</span>
          </span>
        </div>
      </TableCell>
      <TableCell className="hidden px-4 py-3 text-ink md:table-cell xl:whitespace-normal">
        <time dateTime={order.placedAt}>{placedLabel}</time>
      </TableCell>
      <TableCell className="hidden px-4 py-3 text-ink md:table-cell xl:whitespace-normal">{order.brand}</TableCell>
      <TableCell className={`hidden px-4 py-3 text-ink-muted md:table-cell xl:whitespace-normal ${CLUSTER}`}>
        {channel}
      </TableCell>
      <TableCell className="px-3 py-3 md:px-4">
        {/* Narrow screens drop the Payment column; it stacks under the status, aligned to the dot. */}
        <div className="flex flex-col items-start gap-1">
          <OrderStatusBadge status={order.status} />
          <span className="pl-2.5 md:hidden">
            <PaymentStatus payment={order.payment} />
          </span>
        </div>
      </TableCell>
      <TableCell className="hidden px-4 py-3 md:table-cell">
        <PaymentStatus payment={order.payment} />
      </TableCell>
      <TableCell className="py-3 pr-1.5 pl-1 text-right md:pr-2 md:pl-4">
        <ViewButton label={`View order ${order.code}`} onClick={() => onView?.(order)} />
      </TableCell>
    </TableRow>
  );
}
