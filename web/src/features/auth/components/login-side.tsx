import { cn } from "cn";

const BRANDS = ["Gamcheon", "Aurelia's Inasal", "King Kung's Kafé"];

const LINES = [
  "M-30 566C99 468 169 485 251 435S365 277 410 177S448 93 480 50",
  "M-30 619C97 520 175 532 266 477S378 323 426 227S461 157 490 113",
  "M-30 673C95 575 181 574 278 520S391 372 441 278S474 223 502 184",
  "M-30 732C91 635 188 616 290 563S405 423 455 330S487 290 514 255",
];

export default function LoginSide({ className }: { className?: string }) {
  return (
    <aside
      aria-label="KKFC Web Management"
      className={cn(
        "relative isolate flex flex-col gap-4 overflow-hidden bg-[rgb(25,41,62)] px-6 py-5 text-white sm:px-8 lg:justify-between lg:gap-0 lg:py-12",
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

      <p className="motion-safe:animate-rise">
        <span className="text-xl font-bold tracking-[0.12em] lg:text-3xl">KKFC</span>{" "}
        <span className="text-base text-[#c7d9ed] lg:mt-2 lg:block lg:text-lg">Web Management</span>
      </p>

      <ul className="flex flex-wrap gap-x-4 gap-y-1 text-sm text-[#c7d9ed] lg:block lg:text-base lg:text-white">
        {BRANDS.map((brand, index) => (
          <li
            key={brand}
            className="motion-safe:animate-rise lg:border-t lg:border-[#30445a] lg:py-4 lg:last:pb-0"
            style={{ animationDelay: `${300 + index * 80}ms` }}
          >
            {brand}
          </li>
        ))}
      </ul>
    </aside>
  );
}
