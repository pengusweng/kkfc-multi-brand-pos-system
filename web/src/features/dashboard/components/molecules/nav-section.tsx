import NavLink from "../atoms/nav-link";
import NavSectionLabel from "../atoms/nav-section-label";
import type { NavGroup } from "../../utils/navItems";

type NavSectionProps = NavGroup & {
  pathname: string;
  collapsed: boolean;
  onNavigate?: () => void;
};

export default function NavSection({ label, items, pathname, collapsed, onNavigate }: NavSectionProps) {
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
              active={pathname === item.href}
              collapsed={collapsed}
              onNavigate={onNavigate}
            />
          </li>
        ))}
      </ul>
    </div>
  );
}
