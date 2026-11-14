"use client";

import { useState } from "react";
import Pagination from "@/src/components/ui/molecules/pagination";
import PageTitle from "@/src/features/dashboard/components/atoms/page-title";
import OrderDetailModal from "../components/organisms/order-detail-modal";
import OrdersFilterBar from "../components/organisms/orders-filter-bar";
import OrdersTable from "../components/organisms/orders-table";
import { useTodayInManila } from "../hooks/useTodayInManila";
import {
  filterOrders,
  ORDERS_PAGE_SIZE,
  statusCounts,
  type OrderDetail,
  type OrderFilters,
  type OrderStatusFilter,
  type PaymentStatus,
} from "../utils/orders";
import { SAMPLE_ORDERS } from "../utils/sample-orders";

// Static for now: SAMPLE_ORDERS stands in until a useOrders hook fetches the
// list, and filtering runs here instead of on the server.
export default function OrdersPage() {
  const [query, setQuery] = useState("");
  const [status, setStatus] = useState<OrderStatusFilter>("all");
  const [brand, setBrand] = useState<string | undefined>();
  const [payment, setPayment] = useState<PaymentStatus | undefined>();
  const [dates, setDates] = useState<{ from?: string; to?: string }>({});
  const today = useTodayInManila();

  // Kept after closing so the dialog's content doesn't blank out mid-exit.
  const [viewing, setViewing] = useState<OrderDetail | null>(null);
  const [modalOpen, setModalOpen] = useState(false);

  const filters: OrderFilters = { search: query, status, brand, payment, from: dates.from, to: dates.to };
  const matches = filterOrders(SAMPLE_ORDERS, filters);

  // Any filter change returns to page 1.
  const filterKey = `${status}|${brand ?? ""}|${payment ?? ""}|${query.trim()}|${dates.from ?? ""}|${dates.to ?? ""}`;
  const [paging, setPaging] = useState({ filterKey, page: 1 });
  if (paging.filterKey !== filterKey) setPaging({ filterKey, page: 1 });
  const page = paging.filterKey === filterKey ? paging.page : 1;
  const totalPages = Math.max(1, Math.ceil(matches.length / ORDERS_PAGE_SIZE));
  const orders = matches.slice((page - 1) * ORDERS_PAGE_SIZE, page * ORDERS_PAGE_SIZE);
  const filtered = Boolean(query.trim() || brand || payment || dates.from || dates.to || status !== "all");

  return (
    <section className="motion-safe:animate-page-in">
      <PageTitle>Orders</PageTitle>

      <OrdersFilterBar
        query={query}
        onQueryChange={setQuery}
        brand={brand}
        onBrandChange={setBrand}
        payment={payment}
        onPaymentChange={setPayment}
        dates={dates}
        onDatesChange={setDates}
        maxDate={today}
        status={status}
        onStatusChange={setStatus}
        counts={statusCounts(SAMPLE_ORDERS, filters)}
        resultCount={matches.length}
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
        emptyMessage={filtered ? "No orders match these filters." : "No orders yet."}
        onView={(order) => {
          setViewing(orders.find((match) => match.id === order.id) ?? null);
          setModalOpen(true);
        }}
        footer={
          matches.length > 0 ? (
            <Pagination
              page={page}
              pageSize={ORDERS_PAGE_SIZE}
              total={matches.length}
              totalPages={totalPages}
              onPageChange={(next) => setPaging({ filterKey, page: next })}
            />
          ) : null
        }
      />

      <OrderDetailModal order={viewing} open={modalOpen} onOpenChange={setModalOpen} />
    </section>
  );
}
