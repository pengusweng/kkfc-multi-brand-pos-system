"use client";

import { ChefHat, CircleAlert, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Dialog, DialogClose, DialogContent, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import DetailRow from "@/src/components/ui/molecules/detail-row";
import {
  CHANNEL_LABEL,
  formatPlacedAt,
  PAYMENT_METHOD_LABEL,
  type KitchenTicket,
  type OrderDetail,
  type OrderSummary,
} from "../../utils/orders";
import OrderStatusBadge from "../atoms/order-status-badge";
import PaymentStatus from "../atoms/payment-status";
import OrderDetailSkeleton from "../molecules/order-detail-skeleton";
import OrderItems from "../molecules/order-items";
import OrderTimeline from "../molecules/order-timeline";

type OrderDetailModalProps = {
  /** The table row, shown straight away. */
  order: OrderSummary | null;
  /** The row with its lines and kitchen ticket, once loaded. */
  detail: OrderDetail | null;
  /** Why the lines couldn't load, if they couldn't. */
  error?: string | null;
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

export default function OrderDetailModal({
  order,
  detail,
  error = null,
  open,
  onOpenChange,
  onOpenTicket,
}: OrderDetailModalProps) {
  // The detail response is the fresher copy of the same order.
  const shown = detail ?? order;
  const placed = shown ? formatPlacedAt(shown.placedAt) : null;

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
              {shown?.code}
            </DialogTitle>
            {shown ? <OrderStatusBadge status={shown.status} /> : null}
          </div>
          <DialogClose
            render={<Button variant="ghost" size="icon-lg" className="size-10 text-ink-muted hover:text-ink" />}
          >
            <X aria-hidden="true" className="size-5" />
            <span className="sr-only">Close</span>
          </DialogClose>
        </DialogHeader>

        {shown ? (
          <div className="overflow-y-auto px-6 pt-2 pb-6" aria-busy={!detail && !error}>
            {/* The header already draws a rule above the first row. */}
            <dl className="[&>div:first-child]:border-t-0">
              <DetailRow label="Brand">{shown.brand}</DetailRow>
              <DetailRow label="Channel">
                <span className="flex flex-col gap-0.5">
                  <span>
                    {CHANNEL_LABEL[shown.channel]}
                    {shown.table ? <span className="text-ink-muted"> · Table {shown.table}</span> : null}
                  </span>
                  {shown.externalReference ? <Code>{shown.externalReference}</Code> : null}
                </span>
              </DetailRow>
              <DetailRow label="Placed">
                <time dateTime={shown.placedAt}>
                  {placed?.date}, <span className="whitespace-nowrap">{placed?.time}</span>
                </time>
              </DetailRow>
              <DetailRow label="Payment">
                <span className="flex flex-col gap-0.5">
                  <span className="flex flex-wrap items-baseline gap-x-1.5">
                    <PaymentStatus payment={shown.payment} />
                    {shown.paymentMethod ? (
                      <span className="text-ink-muted">· {PAYMENT_METHOD_LABEL[shown.paymentMethod]}</span>
                    ) : null}
                  </span>
                  {shown.paymentReference ? <Code>{shown.paymentReference}</Code> : null}
                </span>
              </DetailRow>
              {shown.notes ? <DetailRow label="Order note">{shown.notes}</DetailRow> : null}
            </dl>

            {detail ? (
              <>
                <OrderItems order={detail} />
                <OrderTimeline order={detail} />
              </>
            ) : error ? (
              <p
                role="alert"
                className="mt-6 flex items-start gap-2.5 rounded-lg bg-destructive/8 px-3 py-2.5 text-sm leading-5 text-danger-ink dark:text-destructive"
              >
                <CircleAlert aria-hidden="true" className="mt-px size-4 shrink-0 text-destructive" />
                {error}
              </p>
            ) : (
              <>
                <p className="sr-only" role="status">
                  Loading order items…
                </p>
                <OrderDetailSkeleton />
              </>
            )}
          </div>
        ) : null}

        {detail ? (
          <DialogFooter className="mx-0 mb-0 flex-row items-center justify-between gap-4 border-hairline bg-transparent px-6 py-4 sm:justify-between">
            {detail.ticket ? (
              <>
                <p className="text-sm text-ink-muted">
                  Ticket <span className="font-semibold text-ink">{detail.ticket.number}</span>
                </p>
                <Button
                  variant="outline"
                  size="lg"
                  className="h-10 cursor-pointer px-4 font-semibold"
                  onClick={() => detail.ticket && onOpenTicket?.(detail.ticket, detail)}
                >
                  <ChefHat aria-hidden="true" />
                  Open kitchen ticket
                </Button>
              </>
            ) : (
              <p className="text-sm text-ink-muted">{noTicketReason(detail)}</p>
            )}
          </DialogFooter>
        ) : null}
      </DialogContent>
    </Dialog>
  );
}
