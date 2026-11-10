import type { Ref } from "react";

// The white "you are here" pill. One per nav: it slides behind the links to the
// active one instead of each link painting its own background.
// Hidden until first positioned, so it never slides in from the top on load.
export default function NavIndicator({ ref }: { ref: Ref<HTMLSpanElement> }) {
  return (
    <span
      ref={ref}
      aria-hidden="true"
      className="pointer-events-none absolute inset-x-3 top-0 h-9 rounded-md bg-rail-pill opacity-0 data-ready:opacity-100 data-ready:transition-transform data-ready:duration-300 data-ready:ease-drawer motion-reduce:transition-none"
    />
  );
}
