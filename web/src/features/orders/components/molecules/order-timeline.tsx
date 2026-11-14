import { formatEventTime, orderTimeline, type OrderDetail, type OrderStatus } from "../../utils/orders";

// The latest step takes the order's status color, matching its pill; earlier
// steps are quiet. A cancellation is always red.
const LATEST_DOT: Record<OrderStatus, string> = {
  DRAFT: "bg-ink-muted",
  CONFIRMED: "bg-[#46566c] dark:bg-[oklch(0.8_0.03_255)]",
  PREPARING: "bg-[#1b5a96] dark:bg-[oklch(0.74_0.11_250)]",
  COMPLETED: "bg-[#2e8a52] dark:bg-[oklch(0.72_0.13_150)]",
  CANCELLED: "bg-[#c2372e] dark:bg-[oklch(0.68_0.17_27)]",
};

export default function OrderTimeline({ order }: { order: OrderDetail }) {
  const events = orderTimeline(order);

  return (
    <section aria-labelledby="order-history-heading" className="mt-6">
      <h4 id="order-history-heading" className="mb-1 text-sm font-semibold text-ink">
        History
      </h4>

      <ol className="border-t border-hairline pt-3">
        {events.map((event, index) => {
          const latest = index === events.length - 1;
          return (
            <li
              key={event.key}
              className="relative grid grid-cols-[0.625rem_minmax(0,1fr)_auto] gap-x-3 pb-4 last:pb-0"
            >
              {/* The rail runs from this dot down to the next one. */}
              {latest ? null : (
                <span
                  aria-hidden="true"
                  className="absolute top-[1.125rem] -bottom-1 left-[calc(0.3125rem-0.5px)] w-px bg-hairline"
                />
              )}
              <span
                aria-hidden="true"
                className={`mt-1.5 size-2.5 rounded-full ${
                  latest ? LATEST_DOT[order.status] : "border-[1.5px] border-ink-muted/45 bg-card"
                }`}
              />
              <div className="min-w-0 text-sm">
                <p className={latest ? "font-semibold text-ink" : "text-ink"}>{event.label}</p>
                {event.detail ? (
                  <p className="mt-0.5 text-[0.8125rem] leading-5 text-ink-muted">{event.detail}</p>
                ) : null}
              </div>
              <time
                dateTime={event.time}
                className="text-right text-[0.8125rem] leading-5 whitespace-nowrap text-ink-muted"
              >
                {formatEventTime(event.time, order.placedAt)}
              </time>
            </li>
          );
        })}
      </ol>
    </section>
  );
}
