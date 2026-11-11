import {
  BookOpen,
  Clock,
  House,
  ShieldCheck,
  ShoppingBag,
  Soup,
  Users,
  type LucideIcon,
} from "lucide-react";
import { STAFF_ACCOUNT_ROLES } from "@/src/features/auth/utils/webRoles";

export type NavItem = {
  label: string;
  href: string;
  icon: LucideIcon;
  count?: number;
  /** Only these roles see the link; omit for every web role. */
  roles?: ReadonlySet<string>;
};

export type NavGroup = {
  label?: string;
  items: NavItem[];
};

export const NAV_GROUPS: NavGroup[] = [
  { items: [{ label: "Workspace", href: "/dashboard", icon: House }] },
  {
    label: "Operations",
    items: [
      { label: "Orders", href: "/dashboard/orders", icon: ShoppingBag },
      { label: "Menu & Availability", href: "/dashboard/menu", icon: Soup },
      { label: "Kitchen Exceptions", href: "/dashboard/kitchen-exceptions", icon: Clock },
    ],
  },
  {
    label: "Administration",
    items: [
      { label: "Recipes", href: "/dashboard/recipes", icon: BookOpen },
      { label: "Audit History", href: "/dashboard/audit-history", icon: ShieldCheck },
      { label: "Staff Accounts", href: "/dashboard/staff", icon: Users, roles: STAFF_ACCOUNT_ROLES },
    ],
  },
];

/** The menu as a given role sees it: hidden links removed, then empty groups dropped. */
export function navGroupsFor(role: string): NavGroup[] {
  return NAV_GROUPS.map((group) => ({
    ...group,
    items: group.items.filter((item) => !item.roles || item.roles.has(role)),
  })).filter((group) => group.items.length > 0);
}
