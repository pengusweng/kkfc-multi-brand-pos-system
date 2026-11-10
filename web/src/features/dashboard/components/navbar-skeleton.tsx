import { RailTransition, WordmarkTransition } from "@/src/components/layout/shared-transitions";
import { NAV_GROUPS } from "../utils/navItems";

// Placeholder rail at the navbar's exact size, shown while the session is checked.
// It carries the rail transition name, so the login panel can morph straight into it.
export default function NavbarSkeleton() {
  return (
    <RailTransition>
      <aside
        aria-hidden="true"
        className="sticky top-0 z-40 flex shrink-0 flex-col bg-rail text-white lg:h-dvh lg:w-60"
      >
        <div className="flex h-16 items-center justify-between px-4">
          <WordmarkTransition>
            <span className="inline-block text-xl font-bold tracking-[0.12em]">KKFC</span>
          </WordmarkTransition>
          <span className="size-9" />
        </div>

        <div className="hidden flex-1 px-3 lg:block">
          {NAV_GROUPS.map((group) => (
            <div key={group.label ?? "main"}>
              {group.label ? <div className="mx-2.5 mt-6 mb-3 h-2.5 w-20 rounded-full bg-white/8" /> : null}
              {group.items.map((item) => (
                <div key={item.href} className="flex h-9 items-center gap-2.5 px-2.5">
                  <span className="size-5 rounded-md bg-white/10" />
                  <span className="h-2.5 w-24 rounded-full bg-white/10" />
                </div>
              ))}
            </div>
          ))}
        </div>

        <div className="hidden border-t border-rail-line lg:block">
          <div className="mx-3 mt-2 flex h-9 items-center gap-2.5 px-2.5">
            <span className="size-5 rounded-md bg-white/10" />
            <span className="h-2.5 w-20 rounded-full bg-white/10" />
          </div>
          <div className="flex items-center gap-3 px-4 py-4">
            <span className="size-8 rounded-full bg-white/10" />
            <span className="h-2.5 w-20 rounded-full bg-white/10" />
          </div>
        </div>
      </aside>
    </RailTransition>
  );
}
