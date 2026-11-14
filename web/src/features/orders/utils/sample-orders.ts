import type { KitchenTicket, OrderChannel, OrderDetail, OrderItem } from "./orders";

// Placeholder orders until the list and detail are wired to the API. Menu
// items, modifiers and prices come from the Sprint 1 seed data.

function ticket(number: string, steps: Partial<Omit<KitchenTicket, "id" | "number">> = {}): KitchenTicket {
  return {
    id: `ticket-${number}`,
    number,
    acknowledgedAt: null,
    preparationStartedAt: null,
    readyAt: null,
    handedOverAt: null,
    ...steps,
  };
}

const NONE = {
  confirmedAt: null,
  completedAt: null,
  cancelledAt: null,
  cancellationReason: null,
  table: null,
  externalReference: null,
  paymentMethod: null,
  paymentReference: null,
  notes: null,
  ticket: null,
} as const;

const DETAILED: OrderDetail[] = [
  {
    ...NONE,
    id: "1",
    code: "GC-00012",
    date: "2026-11-14",
    brand: "Gamcheon",
    channel: "DINE_IN",
    status: "PREPARING",
    payment: "UNPAID",
    table: "4",
    placedAt: "2026-11-14T12:05:31+08:00",
    confirmedAt: "2026-11-14T12:06:02+08:00",
    ticket: ticket("T-012", {
      acknowledgedAt: "2026-11-14T12:06:40+08:00",
      preparationStartedAt: "2026-11-14T12:08:15+08:00",
    }),
    items: [
      {
        id: "1a",
        name: "Bibimbap",
        quantity: 2,
        unitPrice: 229,
        notes: "One of the two without gochujang",
        modifiers: [{ id: "m1", name: "Add egg", price: 20 }],
      },
      {
        id: "1b",
        name: "Korean Fried Chicken (6 pc)",
        quantity: 1,
        unitPrice: 220,
        notes: null,
        modifiers: [{ id: "m2", name: "Less spicy", price: 0 }],
      },
      { id: "1c", name: "Mango Bingsu", quantity: 1, unitPrice: 199, notes: "Serve after the mains", modifiers: [] },
    ],
  },
  {
    ...NONE,
    id: "2",
    code: "AI-00008",
    date: "2026-11-14",
    brand: "Aurelia's Inasal",
    channel: "GRABFOOD",
    status: "CONFIRMED",
    payment: "PAID",
    externalReference: "GF-8KQ2-4471",
    paymentMethod: "PLATFORM_SETTLED",
    placedAt: "2026-11-14T12:11:09+08:00",
    confirmedAt: "2026-11-14T12:11:40+08:00",
    ticket: ticket("T-008"),
    items: [
      {
        id: "2a",
        name: "Paa Inasal",
        quantity: 2,
        unitPrice: 179,
        notes: null,
        modifiers: [
          { id: "m3", name: "Garlic rice", price: 20 },
          { id: "m4", name: "Chicken oil", price: 0 },
        ],
      },
      { id: "2b", name: "Halo-halo", quantity: 1, unitPrice: 109, notes: null, modifiers: [] },
    ],
  },
  {
    ...NONE,
    id: "3",
    code: "KK-00005",
    date: "2026-11-14",
    brand: "King Kungs Kafé",
    channel: "TAKEAWAY",
    status: "DRAFT",
    payment: "UNPAID",
    placedAt: "2026-11-14T12:14:52+08:00",
    notes: "Picking up at 12:45",
    items: [
      {
        id: "3a",
        name: "Iced Spanish Latte",
        quantity: 1,
        unitPrice: 160,
        notes: null,
        modifiers: [
          { id: "m5", name: "Oat milk", price: 25 },
          { id: "m6", name: "Less ice", price: 0 },
        ],
      },
      { id: "3b", name: "Ube Cheese Pandesal (3 pc)", quantity: 2, unitPrice: 95, notes: null, modifiers: [] },
    ],
  },
  {
    ...NONE,
    id: "4",
    code: "GC-00011",
    date: "2026-11-14",
    brand: "Gamcheon",
    channel: "FOODPANDA",
    status: "COMPLETED",
    payment: "PAID",
    externalReference: "FP-X9A2-0F13",
    paymentMethod: "PLATFORM_SETTLED",
    placedAt: "2026-11-14T11:32:04+08:00",
    confirmedAt: "2026-11-14T11:32:30+08:00",
    completedAt: "2026-11-14T11:53:24+08:00",
    ticket: ticket("T-011", {
      acknowledgedAt: "2026-11-14T11:33:01+08:00",
      preparationStartedAt: "2026-11-14T11:34:12+08:00",
      readyAt: "2026-11-14T11:49:57+08:00",
      handedOverAt: "2026-11-14T11:53:20+08:00",
    }),
    items: [
      {
        id: "4a",
        name: "K-Pop Chicken Box",
        quantity: 1,
        unitPrice: 235,
        notes: null,
        modifiers: [{ id: "m7", name: "Extra side sauce", price: 15 }],
      },
      { id: "4b", name: "Japchae", quantity: 1, unitPrice: 179, notes: null, modifiers: [] },
    ],
  },
  {
    ...NONE,
    id: "5",
    code: "AI-00007",
    date: "2026-11-14",
    brand: "Aurelia's Inasal",
    channel: "DINE_IN",
    status: "CANCELLED",
    payment: "REFUNDED",
    table: "7",
    paymentMethod: "CASH",
    placedAt: "2026-11-14T11:20:10+08:00",
    confirmedAt: "2026-11-14T11:21:02+08:00",
    cancelledAt: "2026-11-14T11:27:45+08:00",
    cancellationReason: "Guest had to leave before the food was served",
    ticket: ticket("T-007", { acknowledgedAt: "2026-11-14T11:21:30+08:00" }),
    items: [
      {
        id: "5a",
        name: "Pork Inasal",
        quantity: 1,
        unitPrice: 199,
        notes: null,
        modifiers: [{ id: "m8", name: "Extra rice", price: 20 }],
      },
      { id: "5b", name: "Batchoy Special", quantity: 1, unitPrice: 145, notes: "Soup on the side", modifiers: [] },
    ],
  },
  {
    ...NONE,
    id: "6",
    code: "KK-00004",
    date: "2026-11-13",
    brand: "King Kungs Kafé",
    channel: "DINE_IN",
    status: "COMPLETED",
    payment: "PAID",
    table: "2",
    paymentMethod: "CARD",
    paymentReference: "APPR-093315",
    placedAt: "2026-11-13T16:40:12+08:00",
    confirmedAt: "2026-11-13T16:40:40+08:00",
    completedAt: "2026-11-13T16:48:20+08:00",
    ticket: ticket("T-004", {
      acknowledgedAt: "2026-11-13T16:41:00+08:00",
      preparationStartedAt: "2026-11-13T16:41:30+08:00",
      readyAt: "2026-11-13T16:47:02+08:00",
      handedOverAt: "2026-11-13T16:48:15+08:00",
    }),
    items: [
      {
        id: "6a",
        name: "Clubhouse Sandwich",
        quantity: 1,
        unitPrice: 195,
        notes: null,
        modifiers: [{ id: "m9", name: "No mayonnaise", price: 0 }],
      },
      {
        id: "6b",
        name: "Americano",
        quantity: 1,
        unitPrice: 120,
        notes: null,
        modifiers: [{ id: "m10", name: "Extra espresso shot", price: 40 }],
      },
    ],
  },
  {
    ...NONE,
    id: "7",
    code: "GC-00010",
    date: "2026-11-13",
    brand: "Gamcheon",
    channel: "TAKEAWAY",
    status: "CANCELLED",
    payment: "UNPAID",
    placedAt: "2026-11-13T15:02:33+08:00",
    cancelledAt: "2026-11-13T15:05:10+08:00",
    cancellationReason: "Customer changed their mind",
    items: [
      {
        id: "7a",
        name: "Tteokbokki",
        quantity: 1,
        unitPrice: 159,
        notes: null,
        modifiers: [{ id: "m11", name: "Add cheese", price: 25 }],
      },
    ],
  },
  {
    ...NONE,
    id: "8",
    code: "AI-00006",
    date: "2026-11-13",
    brand: "Aurelia's Inasal",
    channel: "FOODPANDA",
    status: "COMPLETED",
    payment: "PAID",
    externalReference: "FP-K27D-88AE",
    paymentMethod: "PLATFORM_SETTLED",
    placedAt: "2026-11-13T13:15:48+08:00",
    confirmedAt: "2026-11-13T13:16:20+08:00",
    completedAt: "2026-11-13T13:38:02+08:00",
    ticket: ticket("T-006", {
      acknowledgedAt: "2026-11-13T13:16:55+08:00",
      preparationStartedAt: "2026-11-13T13:18:03+08:00",
      readyAt: "2026-11-13T13:33:41+08:00",
      handedOverAt: "2026-11-13T13:37:58+08:00",
    }),
    items: [
      {
        id: "8a",
        name: "Pecho Inasal",
        quantity: 3,
        unitPrice: 189,
        notes: "Extra calamansi on the side",
        modifiers: [{ id: "m12", name: "Garlic rice", price: 20 }],
      },
    ],
  },
];

// Older, settled orders so the table has enough rows to page through.
const MENU: Record<string, { prefix: string; items: [string, number][] }> = {
  Gamcheon: {
    prefix: "GC",
    items: [
      ["Kimchi Fried Rice", 189],
      ["Bibimbap", 229],
      ["Japchae", 179],
      ["Tteokbokki", 159],
    ],
  },
  "Aurelia's Inasal": {
    prefix: "AI",
    items: [
      ["Paa Inasal", 179],
      ["Pecho Inasal", 189],
      ["Batchoy Special", 145],
      ["Halo-halo", 109],
    ],
  },
  "King Kungs Kafé": {
    prefix: "KK",
    items: [
      ["Americano", 120],
      ["Matcha Latte", 170],
      ["Clubhouse Sandwich", 195],
      ["Ube Cheese Pandesal (3 pc)", 95],
    ],
  },
};

const BRAND_CYCLE = Object.keys(MENU);
const CHANNEL_CYCLE: OrderChannel[] = ["DINE_IN", "TAKEAWAY", "GRABFOOD", "DINE_IN", "FOODPANDA"];
const PLATFORM = new Set<OrderChannel>(["GRABFOOD", "FOODPANDA"]);

/** Manila wall-clock time on a November 2026 day, as an ISO string. */
function at(day: number, minutes: number) {
  const hh = String(Math.floor(minutes / 60)).padStart(2, "0");
  const mm = String(minutes % 60).padStart(2, "0");
  return `2026-11-${String(day).padStart(2, "0")}T${hh}:${mm}:${String((minutes * 7) % 60).padStart(2, "0")}+08:00`;
}

function olderOrder(index: number): OrderDetail {
  const day = 12 - Math.floor(index / 11); // 11 orders a day, Nov 12 back to Nov 10
  const slot = index % 11;
  const brand = BRAND_CYCLE[index % 3];
  const { prefix, items } = MENU[brand];
  const channel = CHANNEL_CYCLE[index % CHANNEL_CYCLE.length];
  const cancelled = index % 9 === 4;
  const start = 20 * 60 - slot * 52; // evening first, walking back through the day
  const [name, price] = items[index % items.length];
  const [sideName, sidePrice] = items[(index + 1) % items.length];
  const orderItems: OrderItem[] = [
    { id: `x${index}a`, name, quantity: 1 + (index % 3), unitPrice: price, notes: null, modifiers: [] },
    ...(index % 2 === 0
      ? [{ id: `x${index}b`, name: sideName, quantity: 1, unitPrice: sidePrice, notes: null, modifiers: [] }]
      : []),
  ];
  const number = `T-${String(100 + index).padStart(3, "0")}`;

  return {
    ...NONE,
    id: `x${index}`,
    code: `${prefix}-${String(12 - slot).padStart(5, "0")}`,
    date: `2026-11-${day}`,
    placedAt: at(day, start),
    brand,
    channel,
    status: cancelled ? "CANCELLED" : "COMPLETED",
    payment: cancelled ? "REFUNDED" : "PAID",
    table: channel === "DINE_IN" ? String(1 + (index % 12)) : null,
    externalReference: PLATFORM.has(channel)
      ? `${channel === "GRABFOOD" ? "GF" : "FP"}-${(4096 + index * 37).toString(16).toUpperCase()}`
      : null,
    paymentMethod: PLATFORM.has(channel) ? "PLATFORM_SETTLED" : index % 2 === 0 ? "CASH" : "CARD",
    confirmedAt: at(day, start + 1),
    completedAt: cancelled ? null : at(day, start + 19),
    cancelledAt: cancelled ? at(day, start + 6) : null,
    cancellationReason: cancelled ? "Customer changed their mind" : null,
    ticket: ticket(
      number,
      cancelled
        ? { acknowledgedAt: at(day, start + 2) }
        : {
            acknowledgedAt: at(day, start + 2),
            preparationStartedAt: at(day, start + 3),
            readyAt: at(day, start + 15),
            handedOverAt: at(day, start + 18),
          },
    ),
    items: orderItems,
  };
}

export const SAMPLE_ORDERS: OrderDetail[] = [...DETAILED, ...Array.from({ length: 32 }, (_, i) => olderOrder(i))];
