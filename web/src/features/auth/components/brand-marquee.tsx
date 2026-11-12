import Image, { type StaticImageData } from "next/image";
import { cn } from "cn";
import aurelias from "@/src/assets/brand/mono/aurelias-inasal.png";
import gamcheon from "@/src/assets/brand/mono/gamcheon.png";
import kingKungs from "@/src/assets/brand/mono/king-kungs-kafe.png";

type Brand = {
  name: string;
  /** White single-ink version; the brand's white fills are knocked out so it reads on navy. */
  logo: StaticImageData;
  /** Largest rendered height in px, for the srcset. */
  height: number;
  /** Per-logo height so a round badge, a script mark and a wide wordmark carry the same weight. */
  className: string;
};

const BRANDS: Brand[] = [
  { name: "Gamcheon", logo: gamcheon, height: 56, className: "h-10 lg:h-14" },
  { name: "Aurelia's Inasal", logo: aurelias, height: 56, className: "h-10 lg:h-14" },
  { name: "King Kung's Kafé", logo: kingKungs, height: 40, className: "h-7 lg:h-10" },
];

// Each half of the track holds the set twice, so a half is always wider than
// the rail and the loop never shows a gap.
const HALF = [...BRANDS, ...BRANDS];

// The kitchen's brands drifting left to right in muted white. The track is two
// identical halves sliding by exactly one half, so the loop is seamless; the
// edges fade out instead of clipping. Hover holds it; reduced motion leaves it still.
export default function BrandMarquee({ className }: { className?: string }) {
  return (
    <section aria-label="Brands" className={cn("group relative overflow-hidden", className)}>
      <ul className="sr-only">
        {BRANDS.map((brand) => (
          <li key={brand.name}>{brand.name}</li>
        ))}
      </ul>

      <div
        aria-hidden="true"
        className="[mask-image:linear-gradient(to_right,transparent,black_20%,black_80%,transparent)]"
      >
        <div className="flex w-max motion-safe:animate-brand-marquee group-hover:[animation-play-state:paused]">
          {[0, 1].map((half) => (
            <div key={half} className="flex shrink-0 items-center gap-12 pr-12 lg:gap-16 lg:pr-16">
              {HALF.map((brand, index) => (
                <Image
                  key={`${brand.name}-${index}`}
                  src={brand.logo}
                  alt=""
                  height={brand.height}
                  width={Math.round((brand.logo.width * brand.height) / brand.logo.height)}
                  className={cn(
                    "w-auto shrink-0 opacity-35 transition-opacity duration-300 select-none hover:opacity-80",
                    brand.className,
                  )}
                  draggable={false}
                />
              ))}
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
