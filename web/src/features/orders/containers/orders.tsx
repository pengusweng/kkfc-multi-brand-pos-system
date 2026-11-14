"use client";

import PageTitle from "@/src/features/dashboard/components/atoms/page-title";
import OrdersTable from "../components/organisms/orders-table";
import { SAMPLE_ORDERS } from "../utils/orders";

// Static for now: SAMPLE_ORDERS stands in until a useOrders hook fetches the list.
export default function OrdersPage() {
  return (
    <section className="motion-safe:animate-page-in">
      <PageTitle>Orders</PageTitle>

      <OrdersTable orders={SAMPLE_ORDERS} />
    </section>
  );
}
