import {
  brandsPageSchema,
  orderDetailSchema,
  ordersPageSchema,
  type BrandsPage,
  type OrderDetailRecord,
  type OrdersPage,
  type OrderStatus,
  type PaymentStatus,
} from "../schemas/orderSchema";

export type OrderListFilters = {
  /** Undefined means every status. */
  status?: OrderStatus;
  /** Partial order code. */
  search?: string;
  brandId?: string;
  payment?: PaymentStatus;
  /** Manila business dates (YYYY-MM-DD), inclusive. */
  from?: string;
  to?: string;
};

export type GetOrdersParams = OrderListFilters & { page: number; limit: number };

async function getJson(path: string): Promise<{ status: number; body: unknown }> {
  let response: Response;
  try {
    response = await fetch(path, {
      headers: { Accept: "application/json" },
      cache: "no-store",
      signal: AbortSignal.timeout(10_000),
    });
  } catch {
    throw new Error("Unable to reach the server. Please try again.");
  }
  if (response.status === 401) throw new Error("Your session has expired. Please sign in again.");
  const body: unknown = response.ok ? await response.json().catch(() => null) : null;
  return { status: response.status, body };
}

export async function getOrders({
  page,
  limit,
  status,
  search,
  brandId,
  payment,
  from,
  to,
}: GetOrdersParams): Promise<OrdersPage> {
  const params = new URLSearchParams({ page: String(page), limit: String(limit) });
  if (status) params.set("status", status);
  if (search) params.set("search", search);
  if (brandId) params.set("brand_id", brandId);
  if (payment) params.set("payment_status", payment);
  if (from) params.set("from", from);
  if (to) params.set("to", to);

  const { status: code, body } = await getJson(`/api/orders?${params}`);
  if (code === 403) throw new Error("You don't have permission to view orders.");
  if (code < 200 || code >= 300) throw new Error("Unable to load orders. Please try again.");

  const result = ordersPageSchema.safeParse(body);
  if (!result.success) throw new Error("The server returned an invalid order list.");
  return result.data;
}

export async function getOrder(brandId: string, orderId: string): Promise<OrderDetailRecord> {
  const { status: code, body } = await getJson(
    `/api/brands/${encodeURIComponent(brandId)}/orders/${encodeURIComponent(orderId)}`,
  );
  if (code === 403) throw new Error("You don't have permission to view this order.");
  if (code === 404) throw new Error("This order no longer exists.");
  if (code < 200 || code >= 300) throw new Error("Unable to load this order. Please try again.");

  const result = orderDetailSchema.safeParse(body);
  if (!result.success) throw new Error("The server returned an invalid order.");
  return result.data;
}

/** Every brand, inactive ones included, since past orders can belong to them. */
export async function getBrands(): Promise<BrandsPage> {
  const { status: code, body } = await getJson("/api/brands?activeOnly=false&limit=100");
  if (code < 200 || code >= 300) throw new Error("Unable to load brands.");

  const result = brandsPageSchema.safeParse(body);
  if (!result.success) throw new Error("The server returned an invalid brand list.");
  return result.data;
}
