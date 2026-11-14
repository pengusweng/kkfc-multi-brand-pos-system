// Mirrors the server's OrderChannel / OrderStatus / PaymentStatus enums.
export type OrderChannel = "DINE_IN" | "TAKEAWAY" | "GRABFOOD" | "FOODPANDA";
export type OrderStatus = "DRAFT" | "CONFIRMED" | "PREPARING" | "COMPLETED" | "CANCELLED";
export type PaymentStatus = "UNPAID" | "PAID" | "REFUNDED";
export type PaymentMethod = "CASH" | "E_WALLET" | "CARD" | "PLATFORM_SETTLED";

export type OrderSummary = {
  id: string;
  /** Brand prefix and daily number, e.g. "GC-00001". */
  code: string;
  /** Manila calendar date as YYYY-MM-DD; what the date filter matches. */
  date: string;
  /** ISO timestamp the order was created. */
  placedAt: string;
  brand: string;
  channel: OrderChannel;
  status: OrderStatus;
  payment: PaymentStatus;
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

/** The brands an order can belong to. Static until brands come from the API. */
export const BRANDS = ["Gamcheon", "Aurelia's Inasal", "King Kungs Kafé"];

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

export type OrderFilters = {
  search: string;
  status: OrderStatusFilter;
  brand?: string;
  payment?: PaymentStatus;
  /** YYYY-MM-DD bounds on the order date, both inclusive. */
  from?: string;
  to?: string;
};

function matchesExceptStatus(order: OrderSummary, filters: OrderFilters) {
  const search = filters.search.trim().toLowerCase();
  return (
    (!search || order.code.toLowerCase().includes(search)) &&
    (!filters.brand || order.brand === filters.brand) &&
    (!filters.payment || order.payment === filters.payment) &&
    (!filters.from || order.date >= filters.from) &&
    (!filters.to || order.date <= filters.to)
  );
}

export function filterOrders<T extends OrderSummary>(orders: T[], filters: OrderFilters): T[] {
  return orders.filter(
    (order) => matchesExceptStatus(order, filters) && (filters.status === "all" || order.status === filters.status),
  );
}

/** Per-status counts under every other filter, so each chip says what picking it would show. */
export function statusCounts(orders: OrderSummary[], filters: OrderFilters): Record<OrderStatusFilter, number> {
  const counts: Record<OrderStatusFilter, number> = {
    all: 0,
    DRAFT: 0,
    CONFIRMED: 0,
    PREPARING: 0,
    COMPLETED: 0,
    CANCELLED: 0,
  };
  for (const order of orders) {
    if (!matchesExceptStatus(order, filters)) continue;
    counts.all += 1;
    counts[order.status] += 1;
  }
  return counts;
}

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
  /** ISO timestamps from the order row; null until that step happens. */
  confirmedAt: string | null;
  completedAt: string | null;
  cancelledAt: string | null;
  cancellationReason: string | null;
  table: string | null;
  /** The platform's own order ID for GrabFood / foodpanda orders. */
  externalReference: string | null;
  paymentMethod: PaymentMethod | null;
  paymentReference: string | null;
  notes: string | null;
  items: OrderItem[];
  ticket: KitchenTicket | null;
};

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
