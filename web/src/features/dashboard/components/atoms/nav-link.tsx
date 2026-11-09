import Link from "next/link";
import { cn } from "cn";
import { Badge } from "@/src/components/ui/atoms/badge";
import type { NavItem } from "../../utils/navItems";
import { railFade } from "../../utils/railFade";

type NavLinkProps = NavItem & {
  active: boolean;
  collapsed: boolean;
  onNavigate?: () => void;
};

export default function NavLink({ label, href, icon: Icon, count, active, collapsed, onNavigate }: NavLinkProps) {
  return (
    <Link
      href={href}
      onClick={onNavigate}
      title={collapsed ? label : undefined}
      aria-current={active ? "page" : undefined}
      className={cn(
        // The icon stays put (centred in the 64px rail); the label fades and is clipped.
        "relative flex h-9 items-center gap-2.5 rounded-md px-2.5 text-sm font-semibold whitespace-nowrap transition-colors outline-none focus-visible:ring-2 focus-visible:ring-white/60",
        active ? "bg-white text-slate-900" : "text-white hover:bg-white/10",
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
