import NavLink, { NavLinkFace } from "../atoms/nav-link";
import NavSectionLabel from "../atoms/nav-section-label";
import type { NavGroup } from "../../utils/navItems";

type NavSectionProps = NavGroup & {
  activeHref?: string;
  collapsed: boolean;
  onNavigate?: (href: string) => void;
  // Render the highlight's copy: same layout, no links, no ids, no roles.
  face?: boolean;
};

export default function NavSection({ label, items, activeHref, collapsed, onNavigate, face = false }: NavSectionProps) {
  const labelId = label && !face ? `nav-${label.toLowerCase()}` : undefined;

  return (
    <div role={face ? undefined : "group"} aria-labelledby={labelId}>
      {label ? (
        <NavSectionLabel id={labelId} collapsed={collapsed}>{label}</NavSectionLabel>
      ) : null}
      <ul className="space-y-1">
        {items.map((item) => (
          <li key={item.href}>
            {face ? (
              <NavLinkFace {...item} collapsed={collapsed} />
            ) : (
              <NavLink
                {...item}
                active={activeHref === item.href}
                collapsed={collapsed}
                onNavigate={onNavigate}
              />
            )}
          </li>
        ))}
      </ul>
    </div>
  );
}
