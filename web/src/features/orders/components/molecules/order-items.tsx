import { MessageSquareText } from "lucide-react";
import { formatPeso, lineTotal, orderTotal, type OrderDetail } from "../../utils/orders";

// The order as the kitchen and the cashier read it: quantity, item, what was
// changed, and any note, with the line total on the right. Notes take Warning
// Gold (DESIGN.md › Status Indicators: modifier notes) so they can't be missed.
export default function OrderItems({ order }: { order: OrderDetail }) {
  const count = order.items.reduce((sum, item) => sum + item.quantity, 0);

  return (
    <section aria-labelledby="order-items-heading" className="mt-6">
      <h4 id="order-items-heading" className="mb-1 flex items-baseline justify-between text-sm font-semibold text-ink">
        Items
        <span className="text-[0.8125rem] font-normal text-ink-muted tabular-nums">
          {count} {count === 1 ? "item" : "items"}
        </span>
      </h4>

      <ul>
        {order.items.map((item) => (
          <li
            key={item.id}
            className="grid grid-cols-[2rem_minmax(0,1fr)_auto] gap-x-3 border-t border-hairline py-3 text-sm"
          >
            <span className="font-semibold text-ink-muted tabular-nums">{item.quantity}×</span>
            <div className="min-w-0">
              <p className="font-semibold text-ink">{item.name}</p>
              {item.modifiers.length > 0 ? (
                <ul className="mt-0.5 text-[0.8125rem] leading-5 text-ink-muted">
                  {item.modifiers.map((modifier) => (
                    <li key={modifier.id}>
                      {modifier.name}
                      {modifier.price > 0 ? <span> +{formatPeso(modifier.price)}</span> : null}
                    </li>
                  ))}
                </ul>
              ) : null}
              {item.notes ? (
                <p className="mt-1.5 flex items-start gap-1.5 text-[0.8125rem] leading-5 text-[#6a5200] dark:text-[oklch(0.86_0.11_85)]">
                  <MessageSquareText aria-hidden="true" className="mt-0.5 size-3.5 shrink-0" strokeWidth={2.25} />
                  <span>
                    <span className="sr-only">Note: </span>
                    {item.notes}
                  </span>
                </p>
              ) : null}
            </div>
            <span className="text-right text-ink">{formatPeso(lineTotal(item))}</span>
          </li>
        ))}
      </ul>

      <p className="flex items-baseline justify-between border-t border-hairline pt-3 text-sm font-semibold text-ink">
        Total
        <span className="text-base">{formatPeso(orderTotal(order))}</span>
      </p>
    </section>
  );
}
