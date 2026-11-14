import { z } from "zod";

export const orderChannelSchema = z.enum(["DINE_IN", "TAKEAWAY", "GRABFOOD", "FOODPANDA"]);
export const orderStatusSchema = z.enum(["DRAFT", "CONFIRMED", "PREPARING", "COMPLETED", "CANCELLED"]);
export const paymentStatusSchema = z.enum(["UNPAID", "PAID", "REFUNDED"]);
export const paymentMethodSchema = z.enum(["CASH", "E_WALLET", "CARD", "PLATFORM_SETTLED"]);

// IDs are Postgres uuid columns; z.guid() accepts any UUID shape (seeded IDs aren't always v4).
const id = z.guid();
const timestamp = z.iso.datetime({ offset: true });
// Prices are Postgres decimals, serialized as JSON strings such as "125.5".
const money = z.coerce.number().refine(Number.isFinite, "Invalid amount.");

// The order row's own columns, shared by the list and detail responses.
const orderFields = {
  order_id: id,
  /** Brand prefix and daily number, e.g. "GC-00001". */
  order_code: z.string(),
  /** Manila business date, serialized as midnight UTC. */
  order_date: timestamp,
  brand_id: id,
  order_channel: orderChannelSchema,
  status: orderStatusSchema,
  payment_status: paymentStatusSchema,
  payment_method: paymentMethodSchema.nullable(),
  payment_reference: z.string().nullable(),
  table_reference: z.string().nullable(),
  external_order_reference: z.string().nullable(),
  notes: z.string().nullable(),
  cancellation_reason: z.string().nullable(),
  confirmed_at: timestamp.nullable(),
  completed_at: timestamp.nullable(),
  cancelled_at: timestamp.nullable(),
  created_at: timestamp,
};

/** One row of GET /api/orders: the order and its brand, without lines or ticket. */
export const orderSummarySchema = z.object({
  ...orderFields,
  brand: z.object({ brand_id: id, code: z.string(), name: z.string() }),
});

export const ordersPageSchema = z.object({
  data: z.array(orderSummarySchema),
  meta: z.object({
    page: z.number().int(),
    limit: z.number().int(),
    total: z.number().int(),
    totalPages: z.number().int(),
    /** Per status under every filter except status, for labelling the status chips. */
    counts: z.object({
      all: z.number().int(),
      DRAFT: z.number().int(),
      CONFIRMED: z.number().int(),
      PREPARING: z.number().int(),
      COMPLETED: z.number().int(),
      CANCELLED: z.number().int(),
    }),
  }),
});

const orderItemSchema = z.object({
  order_item_id: id,
  item_name: z.string(),
  quantity: z.number().int(),
  unit_price: money,
  notes: z.string().nullable(),
  order_item_modifiers_order_item: z.array(
    z.object({ order_item_modifier_id: id, modifier_name: z.string(), additional_price: money }),
  ),
});

const kitchenTicketSchema = z.object({
  kitchen_ticket_id: id,
  /** e.g. "T-001". */
  ticket_number: z.string(),
  acknowledged_at: timestamp.nullable(),
  preparation_started_at: timestamp.nullable(),
  ready_at: timestamp.nullable(),
  handed_over_at: timestamp.nullable(),
});

/** GET /api/brands/:brandId/orders/:orderId: the row plus its lines and kitchen ticket. */
export const orderDetailSchema = z.object({
  ...orderFields,
  order_items_order: z.array(orderItemSchema),
  kitchen_tickets_order: kitchenTicketSchema.nullable(),
});

/** GET /api/brands: only what the brand filter needs. */
export const brandsPageSchema = z.object({
  data: z.array(z.object({ brand_id: id, code: z.string(), name: z.string(), is_active: z.boolean() })),
});

export type OrderChannel = z.infer<typeof orderChannelSchema>;
export type OrderStatus = z.infer<typeof orderStatusSchema>;
export type PaymentStatus = z.infer<typeof paymentStatusSchema>;
export type PaymentMethod = z.infer<typeof paymentMethodSchema>;
export type OrderSummaryRecord = z.infer<typeof orderSummarySchema>;
export type OrdersPage = z.infer<typeof ordersPageSchema>;
export type OrderDetailRecord = z.infer<typeof orderDetailSchema>;
export type BrandsPage = z.infer<typeof brandsPageSchema>;
