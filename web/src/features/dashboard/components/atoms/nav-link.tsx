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

// Shared by the real link and its copy inside the highlight, so the two line
// up to the pixel. The icon stays put (centred in the 64px rail); the label
// fades and is clipped.
const BOX = "relative flex h-9 items-center gap-2.5 rounded-md px-2.5 text-sm font-semibold whitespace-nowrap";

function NavLinkContent({ label, icon: Icon, count, collapsed }: NavItem & { collapsed: boolean }) {
  return (
    <>
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
    </>
  );
}

// The real, focusable link. It is always white: the dark "you are here" text
// belongs to the highlight drawn over it (see NavHighlight), so the text never
// fades color on its own and can't fall out of step with the pill.
export default function NavLink({ href, active, collapsed, onNavigate, ...item }: NavLinkProps) {
  return (
    <Link
      href={href}
      data-nav-href={href}
      onClick={(event) => {
        // New-tab clicks don't navigate this page, so don't move the highlight.
        if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey || event.button !== 0) return;
        onNavigate?.(href);
      }}
      title={collapsed ? item.label : undefined}
      aria-current={active ? "page" : undefined}
      className={cn(
        BOX,
        "text-white transition-colors duration-200 outline-none hover:bg-white/10 focus-visible:ring-2 focus-visible:ring-white/60",
      )}
    >
      <NavLinkContent {...item} href={href} collapsed={collapsed} />
    </Link>
  );
}

// The highlight's copy of a link: same box and content, no behaviour.
export function NavLinkFace({ collapsed, ...item }: NavItem & { collapsed: boolean }) {
  return (
    <div className={BOX}>
      <NavLinkContent {...item} collapsed={collapsed} />
    </div>
  );
}
