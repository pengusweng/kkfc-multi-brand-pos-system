import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { getBrands, getOrder, getOrders, type OrderListFilters } from "../services/orders.service";
import { ORDERS_PAGE_SIZE } from "../utils/orders";

// One request per page. The previous page stays in `data` (isPlaceholderData)
// until the requested one arrives, so counts and totals don't blank out.
export function useOrders({ page, ...filters }: OrderListFilters & { page: number }) {
  return useQuery({
    queryKey: ["orders", { ...filters, page, limit: ORDERS_PAGE_SIZE }],
    queryFn: () => getOrders({ ...filters, page, limit: ORDERS_PAGE_SIZE }),
    placeholderData: keepPreviousData,
    retry: false,
  });
}

/** Lines and kitchen ticket for the detail modal; fetched only while it is open. */
export function useOrder(order: { brandId: string; id: string } | null, enabled: boolean) {
  return useQuery({
    queryKey: ["order", order?.brandId, order?.id],
    queryFn: () => getOrder(order!.brandId, order!.id),
    enabled: enabled && order !== null,
    retry: false,
  });
}

/** Options for the brand filter. Brands rarely change, so one fetch per visit is plenty. */
export function useBrandOptions() {
  return useQuery({
    queryKey: ["brands", "all"],
    queryFn: getBrands,
    select: (page) =>
      page.data
        .map((brand) => ({ value: brand.brand_id, label: brand.is_active ? brand.name : `${brand.name} (inactive)` }))
        .sort((a, b) => a.label.localeCompare(b.label)),
    staleTime: 5 * 60_000,
    retry: false,
  });
}
