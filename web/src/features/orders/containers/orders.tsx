"use client";

import { useState } from "react";
import Pagination from "@/src/components/ui/molecules/pagination";
import PageTitle from "@/src/features/dashboard/components/atoms/page-title";
import { useDebouncedValue } from "@/src/hooks/useDebouncedValue";
import OrderDetailModal from "../components/organisms/order-detail-modal";
import OrdersFilterBar from "../components/organisms/orders-filter-bar";
import OrdersTable from "../components/organisms/orders-table";
import { useBrandOptions, useOrder, useOrders } from "../hooks/useOrders";
import { useTodayInManila } from "../hooks/useTodayInManila";
import {
  ORDERS_PAGE_SIZE,
  toOrderDetail,
  toOrderSummary,
  type OrderStatusFilter,
  type OrderSummary,
  type PaymentStatus,
} from "../utils/orders";

const NO_COUNTS: Record<OrderStatusFilter, number> = {
  all: 0,
  DRAFT: 0,
  CONFIRMED: 0,
  PREPARING: 0,
  COMPLETED: 0,
  CANCELLED: 0,
};

export default function OrdersPage() {
  const [query, setQuery] = useState("");
  const [status, setStatus] = useState<OrderStatusFilter>("all");
  const [brand, setBrand] = useState<string | undefined>();
  const [payment, setPayment] = useState<PaymentStatus | undefined>();
  const [dates, setDates] = useState<{ from?: string; to?: string }>({});
  const search = useDebouncedValue(query.trim());
  const today = useTodayInManila();

  // Kept after closing so the dialog's content doesn't blank out mid-exit.
  const [viewing, setViewing] = useState<OrderSummary | null>(null);
  const [modalOpen, setModalOpen] = useState(false);

  // Any filter change returns to page 1.
  const filterKey = `${status}|${brand ?? ""}|${payment ?? ""}|${search}|${dates.from ?? ""}|${dates.to ?? ""}`;
  const [paging, setPaging] = useState({ filterKey, page: 1 });
  if (paging.filterKey !== filterKey) setPaging({ filterKey, page: 1 });
  const page = paging.filterKey === filterKey ? paging.page : 1;

  const { data, error, isPending, isPlaceholderData } = useOrders({
    page,
    status: status === "all" ? undefined : status,
    search,
    brandId: brand,
    payment,
    from: dates.from,
    to: dates.to,
  });
  const brands = useBrandOptions();
  const detail = useOrder(viewing, modalOpen);

  const orders = data?.data.map(toOrderSummary) ?? [];
  const meta = data?.meta;
  const total = meta?.total ?? 0;
  const filtered = Boolean(query.trim() || brand || payment || dates.from || dates.to || status !== "all");

  let emptyMessage = "No orders match these filters.";
  if (error) emptyMessage = error.message;
  else if (!filtered) emptyMessage = "No orders yet.";

  return (
    <section className="motion-safe:animate-page-in">
      <PageTitle>Orders</PageTitle>

      <OrdersFilterBar
        query={query}
        onQueryChange={setQuery}
        brandOptions={brands.data ?? []}
        brand={brand}
        onBrandChange={setBrand}
        payment={payment}
        onPaymentChange={setPayment}
        dates={dates}
        onDatesChange={setDates}
        maxDate={today}
        status={status}
        onStatusChange={setStatus}
        counts={meta?.counts ?? NO_COUNTS}
        resultCount={total}
        onClear={
          filtered
            ? () => {
                setQuery("");
                setBrand(undefined);
                setPayment(undefined);
                setDates({});
                setStatus("all");
              }
            : undefined
        }
      />

      <OrdersTable
        orders={orders}
        onView={(order) => {
          setViewing(order);
          setModalOpen(true);
        }}
        loading={isPending}
        refreshing={isPlaceholderData}
        skeletonRows={orders.length || ORDERS_PAGE_SIZE}
        emptyMessage={emptyMessage}
        footer={
          total > 0 ? (
            <Pagination
              page={page}
              pageSize={ORDERS_PAGE_SIZE}
              total={total}
              totalPages={meta?.totalPages ?? 1}
              onPageChange={(next) => setPaging({ filterKey, page: next })}
            />
          ) : null
        }
      />

      <OrderDetailModal
        order={viewing}
        detail={viewing && detail.data ? toOrderDetail(viewing, detail.data) : null}
        error={detail.error?.message ?? null}
        open={modalOpen}
        onOpenChange={setModalOpen}
      />
    </section>
  );
}
