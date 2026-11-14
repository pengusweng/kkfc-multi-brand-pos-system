import type {
  OrderChannel,
  OrderDetailRecord,
  OrderStatus,
  OrderSummaryRecord,
  PaymentMethod,
  PaymentStatus,
} from "../schemas/orderSchema";

export type { OrderChannel, OrderStatus, PaymentMethod, PaymentStatus };

/** A row of the orders table. It carries every order column, so the modal can show its summary before the lines load. */
export type OrderSummary = {
  id: string;
  /** Brand prefix and daily number, e.g. "GC-00001". */
  code: string;
  /** Manila business date as YYYY-MM-DD; what the date filter matches. */
  date: string;
  /** ISO timestamp the order was created. */
  placedAt: string;
  brandId: string;
  brand: string;
  channel: OrderChannel;
  status: OrderStatus;
  payment: PaymentStatus;
  paymentMethod: PaymentMethod | null;
  paymentReference: string | null;
  table: string | null;
  /** The platform's own order ID for GrabFood / foodpanda orders. */
  externalReference: string | null;
  notes: string | null;
  /** ISO timestamps; null until that step happens. */
  confirmedAt: string | null;
  completedAt: string | null;
  cancelledAt: string | null;
  cancellationReason: string | null;
};

export const ORDERS_PAGE_SIZE = 15;

export const CHANNEL_LABEL: Record<OrderChannel, string> = {
  DINE_IN: "Dine-in",
  TAKEAWAY: "Takeaway",
  GRABFOOD: "GrabFood",
  FOODPANDA: "foodpanda",
};

export const STATUS_LABEL: Record<OrderStatus, string> = {
  DRAFT: "Draft",
  CONFIRMED: "Confirmed",
  PREPARING: "Preparing",
  COMPLETED: "Completed",
  CANCELLED: "Cancelled",
};

export const PAYMENT_LABEL: Record<PaymentStatus, string> = { PAID: "Paid", UNPAID: "Unpaid", REFUNDED: "Refunded" };

// Pinned to Manila so server and client render the same string (no hydration mismatch).
const ROW_DATE_FORMAT = new Intl.DateTimeFormat("en-PH", {
  timeZone: "Asia/Manila",
  month: "short",
  day: "numeric",
  year: "numeric",
});

const ROW_TIME_FORMAT = new Intl.DateTimeFormat("en-PH", {
  timeZone: "Asia/Manila",
  hour: "numeric",
  minute: "2-digit",
});

/** For the table: "Nov 14, 2026" and "12:05 PM", split so the time never wraps apart. The modal shows seconds. */
export function formatOrderTime(iso: string) {
  const date = new Date(iso);
  return { date: ROW_DATE_FORMAT.format(date), time: ROW_TIME_FORMAT.format(date) };
}

export type OrderStatusFilter = OrderStatus | "all";

export type OrderItemModifier = {
  id: string;
  name: string;
  /** Added to the unit price; 0 for free swaps like "No onions". */ price: number;
};

export type OrderItem = {
  id: string;
  name: string;
  quantity: number;
  unitPrice: number;
  notes: string | null;
  modifiers: OrderItemModifier[];
};

/** Mirrors the server's kitchen ticket timestamps; null until that step happens. */
export type KitchenTicket = {
  id: string;
  /** e.g. "T-001". */
  number: string;
  acknowledgedAt: string | null;
  preparationStartedAt: string | null;
  readyAt: string | null;
  handedOverAt: string | null;
};

export type OrderDetail = OrderSummary & {
  items: OrderItem[];
  ticket: KitchenTicket | null;
};

export function toOrderSummary(row: OrderSummaryRecord): OrderSummary {
  return {
    id: row.order_id,
    code: row.order_code,
    date: row.order_date.slice(0, 10),
    placedAt: row.created_at,
    brandId: row.brand.brand_id,
    brand: row.brand.name,
    channel: row.order_channel,
    status: row.status,
    payment: row.payment_status,
    paymentMethod: row.payment_method,
    paymentReference: row.payment_reference,
    table: row.table_reference,
    externalReference: row.external_order_reference,
    notes: row.notes,
    confirmedAt: row.confirmed_at,
    completedAt: row.completed_at,
    cancelledAt: row.cancelled_at,
    cancellationReason: row.cancellation_reason,
  };
}

/** The table row with its lines and ticket. Order columns come from the detail response, so they are as fresh as the lines. */
export function toOrderDetail(summary: OrderSummary, record: OrderDetailRecord): OrderDetail {
  const ticket = record.kitchen_tickets_order;
  return {
    ...summary,
    status: record.status,
    payment: record.payment_status,
    paymentMethod: record.payment_method,
    paymentReference: record.payment_reference,
    confirmedAt: record.confirmed_at,
    completedAt: record.completed_at,
    cancelledAt: record.cancelled_at,
    cancellationReason: record.cancellation_reason,
    items: record.order_items_order.map((line) => ({
      id: line.order_item_id,
      name: line.item_name,
      quantity: line.quantity,
      unitPrice: line.unit_price,
      notes: line.notes,
      modifiers: line.order_item_modifiers_order_item.map((modifier) => ({
        id: modifier.order_item_modifier_id,
        name: modifier.modifier_name,
        price: modifier.additional_price,
      })),
    })),
    ticket: ticket
      ? {
          id: ticket.kitchen_ticket_id,
          number: ticket.ticket_number,
          acknowledgedAt: ticket.acknowledged_at,
          preparationStartedAt: ticket.preparation_started_at,
          readyAt: ticket.ready_at,
          handedOverAt: ticket.handed_over_at,
        }
      : null,
  };
}

export const PAYMENT_METHOD_LABEL: Record<PaymentMethod, string> = {
  CASH: "Cash",
  E_WALLET: "E-wallet",
  CARD: "Card",
  PLATFORM_SETTLED: "Settled by platform",
};

const peso = new Intl.NumberFormat("en-PH", { style: "currency", currency: "PHP" });

export function formatPeso(amount: number) {
  return peso.format(amount);
}

/** Unit price plus modifiers, times quantity. */
export function lineTotal(item: OrderItem) {
  return (item.unitPrice + item.modifiers.reduce((sum, modifier) => sum + modifier.price, 0)) * item.quantity;
}

export function orderTotal(order: OrderDetail) {
  return order.items.reduce((sum, item) => sum + lineTotal(item), 0);
}

// Pinned to Manila so server and client render the same string (no hydration mismatch).
const PLACED_DATE_FORMAT = new Intl.DateTimeFormat("en-PH", {
  timeZone: "Asia/Manila",
  weekday: "short",
  month: "short",
  day: "numeric",
  year: "numeric",
});

const EVENT_TIME_FORMAT = new Intl.DateTimeFormat("en-PH", {
  timeZone: "Asia/Manila",
  hour: "numeric",
  minute: "2-digit",
  second: "2-digit",
});

const EVENT_DAY_FORMAT = new Intl.DateTimeFormat("en-PH", { timeZone: "Asia/Manila", month: "short", day: "numeric" });

/** Down to the second, with the weekday, split so the time never wraps apart: "Sat, Nov 14, 2026" and "12:05:31 PM". */
export function formatPlacedAt(iso: string) {
  const date = new Date(iso);
  return { date: PLACED_DATE_FORMAT.format(date), time: EVENT_TIME_FORMAT.format(date) };
}

/** Exact time of a history step; the date is added only when it differs from the day the order was placed. */
export function formatEventTime(iso: string, placedAt: string) {
  const time = EVENT_TIME_FORMAT.format(new Date(iso));
  const day = EVENT_DAY_FORMAT.format(new Date(iso));
  return day === EVENT_DAY_FORMAT.format(new Date(placedAt)) ? time : `${day}, ${time}`;
}

export type OrderEvent = {
  key: string;
  label: string;
  time: string;
  detail?: string;
  /** Marks the cancellation so the timeline can draw it in red. */
  cancelled?: boolean;
};

/** Every step the order and its kitchen ticket have reached, oldest first. */
export function orderTimeline(order: OrderDetail): OrderEvent[] {
  const ticket = order.ticket;
  const steps: (OrderEvent | null)[] = [
    { key: "placed", label: "Order placed", time: order.placedAt },
    order.confirmedAt ? { key: "confirmed", label: "Confirmed", time: order.confirmedAt } : null,
    ticket?.acknowledgedAt
      ? { key: "acknowledged", label: `Kitchen took ticket ${ticket.number}`, time: ticket.acknowledgedAt }
      : null,
    ticket?.preparationStartedAt
      ? { key: "preparing", label: "Preparation started", time: ticket.preparationStartedAt }
      : null,
    ticket?.readyAt ? { key: "ready", label: "Passed quality check", time: ticket.readyAt } : null,
    ticket?.handedOverAt ? { key: "handed-over", label: "Handed over", time: ticket.handedOverAt } : null,
    order.completedAt ? { key: "completed", label: "Completed", time: order.completedAt } : null,
    order.cancelledAt
      ? {
          key: "cancelled",
          label: "Cancelled",
          time: order.cancelledAt,
          detail: order.cancellationReason ?? undefined,
          cancelled: true,
        }
      : null,
  ];
  return steps
    .filter((step): step is OrderEvent => step !== null)
    .sort((a, b) => new Date(a.time).getTime() - new Date(b.time).getTime());
}
