// Mirrors the server's OrderChannel / OrderStatus / PaymentStatus enums.
export type OrderChannel = "DINE_IN" | "TAKEAWAY" | "GRABFOOD" | "FOODPANDA";
export type OrderStatus = "DRAFT" | "CONFIRMED" | "PREPARING" | "COMPLETED" | "CANCELLED";
export type PaymentStatus = "UNPAID" | "PAID" | "REFUNDED";

export type OrderSummary = {
  id: string;
  /** Brand prefix and daily number, e.g. "GC-00001". */
  code: string;
  /** Manila calendar date as YYYY-MM-DD. */
  date: string;
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

// order_date is a date-only column, so format it in UTC to keep the day from shifting.
const DATE_FORMAT = new Intl.DateTimeFormat("en-PH", {
  timeZone: "UTC",
  month: "short",
  day: "numeric",
  year: "numeric",
});

export function formatOrderDate(date: string) {
  return DATE_FORMAT.format(new Date(`${date}T00:00:00Z`));
}

/** Placeholder rows until the orders list is wired to the API. */
export const SAMPLE_ORDERS: OrderSummary[] = [
  {
    id: "1",
    code: "GC-00012",
    date: "2026-11-14",
    brand: "Gamcheon",
    channel: "DINE_IN",
    status: "PREPARING",
    payment: "UNPAID",
  },
  {
    id: "2",
    code: "AI-00008",
    date: "2026-11-14",
    brand: "Aurelia's Inasal",
    channel: "GRABFOOD",
    status: "CONFIRMED",
    payment: "PAID",
  },
  {
    id: "3",
    code: "KK-00005",
    date: "2026-11-14",
    brand: "King Kungs Kafé",
    channel: "TAKEAWAY",
    status: "DRAFT",
    payment: "UNPAID",
  },
  {
    id: "4",
    code: "GC-00011",
    date: "2026-11-14",
    brand: "Gamcheon",
    channel: "FOODPANDA",
    status: "COMPLETED",
    payment: "PAID",
  },
  {
    id: "5",
    code: "AI-00007",
    date: "2026-11-14",
    brand: "Aurelia's Inasal",
    channel: "DINE_IN",
    status: "CANCELLED",
    payment: "REFUNDED",
  },
  {
    id: "6",
    code: "KK-00004",
    date: "2026-11-13",
    brand: "King Kungs Kafé",
    channel: "DINE_IN",
    status: "COMPLETED",
    payment: "PAID",
  },
  {
    id: "7",
    code: "GC-00010",
    date: "2026-11-13",
    brand: "Gamcheon",
    channel: "TAKEAWAY",
    status: "CANCELLED",
    payment: "UNPAID",
  },
  {
    id: "8",
    code: "AI-00006",
    date: "2026-11-13",
    brand: "Aurelia's Inasal",
    channel: "FOODPANDA",
    status: "COMPLETED",
    payment: "PAID",
  },
];
