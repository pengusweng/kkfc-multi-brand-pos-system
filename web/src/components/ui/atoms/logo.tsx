import Image from "next/image";
import { cn } from "cn";
import logoOnDark from "@/src/assets/brand/kitchenflow-logo-on-dark.png";

type LogoProps = {
  /** Largest rendered height in px; sizes the srcset. Set the CSS height (e.g. h-7) with className. */
  height: number;
  className?: string;
  /** Above the fold on first paint (login, rail). */
  eager?: boolean;
};

// Light-ink KitchenFlow logo for the navy rail, which stays navy in both themes.
export function Logo({ height, className, eager = false }: LogoProps) {
  return (
    <Image
      src={logoOnDark}
      alt="KitchenFlow"
      height={height}
      width={Math.round((logoOnDark.width * height) / logoOnDark.height)}
      loading={eager ? "eager" : "lazy"}
      className={cn("block w-auto", className)}
    />
  );
}
