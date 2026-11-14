import type { ReactNode } from "react";
import { DataTable, DataTableHead } from "@/src/components/ui/organisms/data-table";
import type { OrderSummary } from "../../utils/orders";
import { CLUSTER, COL, COLUMN_COUNT } from "../../utils/table-columns";
import OrderRow from "../molecules/order-row";
import OrderSkeletonRow from "../molecules/order-skeleton-row";

type OrdersTableProps = {
  orders: OrderSummary[];
  onView?: (order: OrderSummary) => void;
  loading?: boolean;
  refreshing?: boolean;
  skeletonRows?: number;
  emptyMessage?: string;
  footer?: ReactNode;
};

export default function OrdersTable({
  orders,
  onView,
  loading = false,
  refreshing = false,
  skeletonRows,
  emptyMessage = "No orders yet.",
  footer,
}: OrdersTableProps) {
  return (
    <DataTable
      columnCount={COLUMN_COUNT}
      loading={loading}
      refreshing={refreshing}
      loadingLabel="Loading orders…"
      skeletonRows={skeletonRows}
      skeletonRow={(i) => <OrderSkeletonRow index={i} />}
      emptyMessage={emptyMessage}
      footer={footer}
      head={
        <>
          <DataTableHead className={COL.code}>Order code</DataTableHead>
          <DataTableHead className={`hidden md:table-cell ${COL.date}`}>Order date</DataTableHead>
          <DataTableHead className={`hidden md:table-cell ${COL.brand}`}>Brand</DataTableHead>
          <DataTableHead className={`${CLUSTER} hidden md:table-cell ${COL.channel}`}>Channel</DataTableHead>
          <DataTableHead className={`w-px ${COL.status}`}>Status</DataTableHead>
          <DataTableHead className={`hidden w-px md:table-cell ${COL.payment}`}>Payment</DataTableHead>
          <DataTableHead className={`w-px ${COL.view}`}>
            <span className="sr-only">Actions</span>
          </DataTableHead>
        </>
      }
      rows={orders.map((order) => (
        <OrderRow key={order.id} order={order} onView={onView} />
      ))}
    />
  );
}
