import type { Ref } from "react";
import { cn } from "cn";
import NavSection from "./nav-section";
import { NAV_GROUPS } from "../../utils/navItems";

// The "you are here" pill. Rather than a plain shape behind the links (which
// forces each link to switch its own text color as the pill arrives or leaves),
// this is a second copy of the whole menu, painted pill-colored with dark text,
// laid exactly over the real one and clipped to the active link's box. Moving
// the clip moves the pill, and the text is dark precisely where the pill covers
// it, pixel for pixel, on the pill's own curve: words turn dark as the pill's
// edge passes over them, never ahead of it or behind it.
//
// The clip is set by the navbar. On load the pill draws itself across the
// active link rather than popping in; after that, it slides. The copy is inert and hidden from assistive
// tech; the real links underneath stay the interactive ones.
export default function NavHighlight({ ref, collapsed }: { ref: Ref<HTMLDivElement>; collapsed: boolean }) {
  return (
    <div
      ref={ref}
      aria-hidden="true"
      inert
      className={cn(
        // Fully clipped until the navbar places it, so nothing shows before JS runs.
        "pointer-events-none absolute inset-x-0 top-0 z-10 bg-rail-pill px-3 pb-4 text-rail-pill-ink [clip-path:inset(0_0_100%_0)]",
        // Moving between links: the slide.
        "data-ready:transition-[clip-path] data-ready:duration-300 data-ready:ease-drawer",
        // Arriving on load: a slower, decelerating draw, a beat after the rail appears.
        "data-entering:delay-100 data-entering:duration-500 data-entering:ease-out-quart",
        // Reduced motion: the entrance becomes a short fade in place, and moves are instant.
        "motion-reduce:transition-none motion-reduce:data-entering:animate-[vt-fade-in_200ms_ease-out_both]",
      )}
    >
      {NAV_GROUPS.map((group) => (
        <NavSection key={group.label ?? "main"} {...group} collapsed={collapsed} face />
      ))}
    </div>
  );
}
