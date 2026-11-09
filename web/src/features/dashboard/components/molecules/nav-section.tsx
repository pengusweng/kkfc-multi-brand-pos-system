import NavLink from "../atoms/nav-link";
import NavSectionLabel from "../atoms/nav-section-label";
import type { NavGroup } from "../../utils/navItems";

type NavSectionProps = NavGroup & {
  activeHref: string;
  collapsed: boolean;
  onNavigate?: (href: string) => void;
};

export default function NavSection({ label, items, activeHref, collapsed, onNavigate }: NavSectionProps) {
  const labelId = label ? `nav-${label.toLowerCase()}` : undefined;

  return (
    <div role="group" aria-labelledby={labelId}>
      {label && labelId ? (
        <NavSectionLabel id={labelId} collapsed={collapsed}>{label}</NavSectionLabel>
      ) : null}
      <ul className="space-y-1">
        {items.map((item) => (
          <li key={item.href}>
            <NavLink
              {...item}
              active={activeHref === item.href}
              collapsed={collapsed}
              onNavigate={onNavigate}
            />
          </li>
        ))}
      </ul>
    </div>
  );
}
