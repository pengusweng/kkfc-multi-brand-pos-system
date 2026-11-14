"use client";

import { ChefHat, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Dialog, DialogClose, DialogContent, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import DetailRow from "@/src/components/ui/molecules/detail-row";
import {
  CHANNEL_LABEL,
  formatPlacedAt,
  PAYMENT_METHOD_LABEL,
  type KitchenTicket,
  type OrderDetail,
} from "../../utils/orders";
import OrderStatusBadge from "../atoms/order-status-badge";
import PaymentStatus from "../atoms/payment-status";
import OrderItems from "../molecules/order-items";
import OrderTimeline from "../molecules/order-timeline";

type OrderDetailModalProps = {
  order: OrderDetail | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onOpenTicket?: (ticket: KitchenTicket, order: OrderDetail) => void;
};

// DESIGN.md › Elevation: dialogs get Shadow 3. Shadows vanish on the dark
// surface, so dark mode swaps it for a hairline edge instead of stacking both.
const SURFACE =
  "shadow-[0_8px_24px_rgba(25,41,62,0.14),0_2px_8px_rgba(25,41,62,0.08)] dark:shadow-none dark:ring-1 dark:ring-hairline";

// Identifiers: selectable in one click, wrapped anywhere.
function Code({ children }: { children: string }) {
  return <span className="font-mono text-xs break-all text-ink-muted select-all">{children}</span>;
}

// No kitchen ticket exists until an order is confirmed, so say why the button is missing.
function noTicketReason(order: OrderDetail) {
  if (order.status === "CANCELLED") return "Cancelled before it reached the kitchen.";
  return "The kitchen gets a ticket once the order is confirmed.";
}

export default function OrderDetailModal({ order, open, onOpenChange, onOpenTicket }: OrderDetailModalProps) {
  const placed = order ? formatPlacedAt(order.placedAt) : null;
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent
        showCloseButton={false}
        className={`flex max-h-[calc(100dvh-2rem)] flex-col gap-0 overflow-hidden rounded-xl bg-card p-0 text-ink ring-0 sm:max-w-xl ${SURFACE}`}
      >
        <DialogHeader className="flex-row items-center justify-between gap-4 border-b border-hairline py-3 pr-3 pl-6">
          <div className="flex min-w-0 flex-wrap items-center gap-x-3 gap-y-1">
            <DialogTitle className="text-lg font-semibold text-ink tabular-nums">
              <span className="sr-only">Order </span>
              {order?.code}
            </DialogTitle>
            {order ? <OrderStatusBadge status={order.status} /> : null}
          </div>
          <DialogClose
            render={<Button variant="ghost" size="icon-lg" className="size-10 text-ink-muted hover:text-ink" />}
          >
            <X aria-hidden="true" className="size-5" />
            <span className="sr-only">Close</span>
          </DialogClose>
        </DialogHeader>

        {order ? (
          <div className="overflow-y-auto px-6 pt-2 pb-6">
            {/* The header already draws a rule above the first row. */}
            <dl className="[&>div:first-child]:border-t-0">
              <DetailRow label="Brand">{order.brand}</DetailRow>
              <DetailRow label="Channel">
                <span className="flex flex-col gap-0.5">
                  <span>
                    {CHANNEL_LABEL[order.channel]}
                    {order.table ? <span className="text-ink-muted"> · Table {order.table}</span> : null}
                  </span>
                  {order.externalReference ? <Code>{order.externalReference}</Code> : null}
                </span>
              </DetailRow>
              <DetailRow label="Placed">
                <time dateTime={order.placedAt}>
                  {placed?.date}, <span className="whitespace-nowrap">{placed?.time}</span>
                </time>
              </DetailRow>
              <DetailRow label="Payment">
                <span className="flex flex-col gap-0.5">
                  <span className="flex flex-wrap items-baseline gap-x-1.5">
                    <PaymentStatus payment={order.payment} />
                    {order.paymentMethod ? (
                      <span className="text-ink-muted">· {PAYMENT_METHOD_LABEL[order.paymentMethod]}</span>
                    ) : null}
                  </span>
                  {order.paymentReference ? <Code>{order.paymentReference}</Code> : null}
                </span>
              </DetailRow>
              {order.notes ? <DetailRow label="Order note">{order.notes}</DetailRow> : null}
            </dl>

            <OrderItems order={order} />
            <OrderTimeline order={order} />
          </div>
        ) : null}

        {order ? (
          <DialogFooter className="mx-0 mb-0 flex-row items-center justify-between gap-4 border-hairline sm:justify-between bg-transparent px-6 py-4">
            {order.ticket ? (
              <>
                <p className="text-sm text-ink-muted">
                  Ticket <span className="font-semibold text-ink">{order.ticket.number}</span>
                </p>
                <Button
                  variant="outline"
                  size="lg"
                  className="h-10 cursor-pointer px-4 font-semibold"
                  onClick={() => order.ticket && onOpenTicket?.(order.ticket, order)}
                >
                  <ChefHat aria-hidden="true" />
                  Open kitchen ticket
                </Button>
              </>
            ) : (
              <p className="text-sm text-ink-muted">{noTicketReason(order)}</p>
            )}
          </DialogFooter>
        ) : null}
      </DialogContent>
    </Dialog>
  );
}
