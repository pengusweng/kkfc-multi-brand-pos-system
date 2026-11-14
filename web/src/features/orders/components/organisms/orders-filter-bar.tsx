"use client";

import DateRangeField from "@/src/components/ui/molecules/date-range-field";
import SearchField from "@/src/components/ui/molecules/search-field";
import { BRANDS, PAYMENT_LABEL, type OrderStatusFilter, type PaymentStatus } from "../../utils/orders";
import FilterSelect from "../molecules/filter-select";
import StatusFilter from "../molecules/status-filter";

const BRAND_OPTIONS = BRANDS.map((brand) => ({ value: brand, label: brand }));
const PAYMENT_OPTIONS = (["PAID", "UNPAID", "REFUNDED"] as const).map((payment) => ({
  value: payment,
  label: PAYMENT_LABEL[payment],
}));

type OrdersFilterBarProps = {
  query: string;
  onQueryChange: (query: string) => void;
  brand: string | undefined;
  onBrandChange: (brand: string | undefined) => void;
  payment: PaymentStatus | undefined;
  onPaymentChange: (payment: PaymentStatus | undefined) => void;
  dates: { from?: string; to?: string };
  onDatesChange: (dates: { from?: string; to?: string }) => void;
  maxDate: string | undefined;
  status: OrderStatusFilter;
  onStatusChange: (status: OrderStatusFilter) => void;
  counts: Record<OrderStatusFilter, number>;
  resultCount: number;
  /** Shown when any filter is set. */
  onClear?: () => void;
};

// Same card as the staff and audit filter bars. What to look for (code,
// brand, payment, when) above; the status chips and result count below.
export default function OrdersFilterBar({
  query,
  onQueryChange,
  brand,
  onBrandChange,
  payment,
  onPaymentChange,
  dates,
  onDatesChange,
  maxDate,
  status,
  onStatusChange,
  counts,
  resultCount,
  onClear,
}: OrdersFilterBarProps) {
  return (
    <div className="mt-6 flex flex-col gap-3 rounded-xl border border-hairline bg-card p-3 md:px-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:flex-wrap sm:items-center sm:gap-x-4">
        <SearchField label="Search order code" value={query} onChange={onQueryChange} />
        <div className="flex gap-3 sm:contents">
          <FilterSelect
            label="Filter by brand"
            allLabel="All brands"
            options={BRAND_OPTIONS}
            value={brand}
            onChange={onBrandChange}
          />
          <FilterSelect
            label="Filter by payment"
            allLabel="All payments"
            options={PAYMENT_OPTIONS}
            value={payment}
            onChange={onPaymentChange}
            className="sm:w-40"
          />
        </div>
        <DateRangeField value={dates} onChange={onDatesChange} max={maxDate} />
      </div>
      <div className="flex flex-col gap-3 border-t border-hairline pt-3 sm:flex-row sm:flex-wrap sm:items-center sm:gap-x-4">
        <StatusFilter value={status} onChange={onStatusChange} counts={counts} />
        <div className="flex items-center gap-3 sm:ml-auto">
          {onClear ? (
            <button
              type="button"
              onClick={onClear}
              className="cursor-pointer rounded-md px-1 text-sm font-semibold text-ink underline decoration-hairline underline-offset-4 outline-none hover:decoration-ink focus-visible:ring-2 focus-visible:ring-primary/40 motion-safe:animate-in motion-safe:fade-in-0 motion-safe:duration-200"
            >
              Clear filters
            </button>
          ) : null}
          <p aria-live="polite" className="text-sm text-ink-muted tabular-nums">
            {resultCount} {resultCount === 1 ? "order" : "orders"}
          </p>
        </div>
      </div>
    </div>
  );
}
