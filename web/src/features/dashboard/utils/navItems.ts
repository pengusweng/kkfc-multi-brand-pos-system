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

export type NavItem = {
  label: string;
  href: string;
  icon: LucideIcon;
  count?: number;
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
      { label: "Staff Accounts", href: "/dashboard/staff", icon: Users },
    ],
  },
];

