"use client";

import { useState } from "react";
import PageTitle from "@/src/features/dashboard/components/atoms/page-title";
import OrderDetailModal from "../components/organisms/order-detail-modal";
import OrdersTable from "../components/organisms/orders-table";
import type { OrderDetail } from "../utils/orders";
import { SAMPLE_ORDERS } from "../utils/sample-orders";

// Static for now: SAMPLE_ORDERS stands in until a useOrders hook fetches the list.
export default function OrdersPage() {
  // Kept after closing so the dialog's content doesn't blank out mid-exit.
  const [viewing, setViewing] = useState<OrderDetail | null>(null);
  const [modalOpen, setModalOpen] = useState(false);

  return (
    <section className="motion-safe:animate-page-in">
      <PageTitle>Orders</PageTitle>

      <OrdersTable
        orders={SAMPLE_ORDERS}
        onView={(order) => {
          setViewing(SAMPLE_ORDERS.find((sample) => sample.id === order.id) ?? null);
          setModalOpen(true);
        }}
      />

      <OrderDetailModal order={viewing} open={modalOpen} onOpenChange={setModalOpen} />
    </section>
  );
}
