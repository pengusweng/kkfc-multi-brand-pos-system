import { cn } from "cn";
import { RailTransition, WordmarkTransition } from "@/src/components/layout/shared-transitions";
import { Logo } from "@/src/components/ui/atoms/logo";

const BRANDS = ["Gamcheon", "Aurelia's Inasal", "King Kung's Kafé"];

const LINES = [
  "M-30 566C99 468 169 485 251 435S365 277 410 177S448 93 480 50",
  "M-30 619C97 520 175 532 266 477S378 323 426 227S461 157 490 113",
  "M-30 673C95 575 181 574 278 520S391 372 441 278S474 223 502 184",
  "M-30 732C91 635 188 616 290 563S405 423 455 330S487 290 514 255",
];

export default function LoginSide({ className }: { className?: string }) {
  return (
    <RailTransition>
    <aside
      aria-label="KitchenFlow Web Management"
      className={cn(
        "relative isolate flex flex-col gap-4 overflow-hidden bg-rail px-6 py-5 text-white sm:px-8 lg:justify-between lg:gap-0 lg:py-12",
        className,
      )}
    >
      <svg
        aria-hidden="true"
        viewBox="0 0 464 910"
        preserveAspectRatio="xMaxYMid slice"
        fill="none"
        stroke="currentColor"
        strokeWidth="1"
        className="pointer-events-none absolute inset-y-0 right-0 -z-10 h-full w-1/2 text-primary opacity-50 lg:inset-y-auto lg:top-1/2 lg:h-72 lg:w-full lg:-translate-y-1/2 lg:opacity-70 lg:[mask-image:linear-gradient(to_bottom,transparent,black_15%,black_85%,transparent)]"
      >
        {LINES.map((d, index) => (
          <path
            key={d}
            d={d}
            pathLength={1}
            strokeDasharray="1"
            vectorEffect="non-scaling-stroke"
            className="motion-safe:animate-draw"
            style={{ animationDelay: `${200 + index * 120}ms` }}
          />
        ))}
      </svg>

      <div className="flex items-center gap-3 motion-safe:animate-rise lg:block">
        <WordmarkTransition>
          <span className="inline-block">
            <Logo height={40} eager className="h-7 lg:h-10" />
          </span>
        </WordmarkTransition>
        <p className="text-base text-rail-muted lg:mt-3 lg:text-lg">Web Management</p>
      </div>

      <ul className="flex flex-wrap gap-x-4 gap-y-1 text-sm text-rail-muted lg:block lg:text-base lg:text-white">
        {BRANDS.map((brand, index) => (
          <li
            key={brand}
            className="motion-safe:animate-rise lg:border-t lg:border-rail-line lg:py-4 lg:last:pb-0"
            style={{ animationDelay: `${300 + index * 80}ms` }}
          >
            {brand}
          </li>
        ))}
      </ul>
    </aside>
    </RailTransition>
  );
}
