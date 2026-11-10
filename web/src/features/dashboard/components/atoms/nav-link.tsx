import Link from "next/link";
import { cn } from "cn";
import { Badge } from "@/src/components/ui/atoms/badge";
import type { NavItem } from "../../utils/navItems";
import { railFade } from "../../utils/railFade";

type NavLinkProps = NavItem & {
  active: boolean;
  collapsed: boolean;
  onNavigate?: (href: string) => void;
};

export default function NavLink({ label, href, icon: Icon, count, active, collapsed, onNavigate }: NavLinkProps) {
  return (
    <Link
      href={href}
      data-nav-href={href}
      onClick={(event) => {
        // New-tab clicks don't navigate this page, so don't move the indicator.
        if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey || event.button !== 0) return;
        onNavigate?.(href);
      }}
      title={collapsed ? label : undefined}
      aria-current={active ? "page" : undefined}
      className={cn(
        // The icon stays put (centred in the 64px rail); the label fades and is clipped.
        "relative flex h-9 items-center gap-2.5 rounded-md px-2.5 text-sm font-semibold whitespace-nowrap transition-colors duration-200 outline-none focus-visible:ring-2 focus-visible:ring-white/60",
        // The white background comes from the shared NavIndicator behind the links.
        // Turn dark as the indicator arrives, not before (dark-on-navy would flash).
        active ? "text-rail-pill-ink delay-150" : "text-white hover:bg-white/10",
      )}
    >
      <Icon aria-hidden="true" className="size-5 shrink-0" strokeWidth={1.75} />
      <span className={cn("flex-1 truncate", railFade(collapsed))}>{label}</span>
      {count ? (
        <Badge
          aria-label={`${count} pending`}
          className={cn(collapsed && "lg:absolute lg:-top-1.5 lg:right-0.5")}
        >
          {count}
        </Badge>
      ) : null}
    </Link>
  );
}
