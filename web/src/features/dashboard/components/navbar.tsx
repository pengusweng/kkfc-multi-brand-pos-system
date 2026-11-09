"use client";

import { useState } from "react";
import { usePathname } from "next/navigation";
import { Menu, X } from "lucide-react";
import { cn } from "cn";
import { Button } from "@/components/ui/button";
import NavSection from "./molecules/nav-section";
import NavUser, { type NavUserProps } from "./molecules/nav-user";
import { NAV_GROUPS } from "../utils/navItems";
import { useLogout } from "@/src/features/auth/hooks/useLogout";

const DESKTOP_QUERY = "(min-width: 64rem)";

export default function Navbar({ user }: { user: Pick<NavUserProps, "name" | "role"> }) {
  const pathname = usePathname();
  const [open, setOpen] = useState(false);
  const [collapsed, setCollapsed] = useState(false);
  const close = () => setOpen(false);
  const logout = useLogout();

  // Mobile: the burger opens the dropdown menu. Desktop: it collapses the sidebar to icons.
  const toggle = () => {
    if (window.matchMedia(DESKTOP_QUERY).matches) setCollapsed((value) => !value);
    else setOpen((value) => !value);
  };

  return (
    <aside
      className={cn(
        "sticky top-0 z-40 flex shrink-0 flex-col bg-[rgb(25,41,62)] text-white transition-[width] lg:h-dvh",
        collapsed ? "lg:w-16" : "lg:w-60",
      )}
    >
      <div className={cn("flex h-16 items-center justify-between px-4", collapsed && "lg:justify-center lg:px-0")}>
        <span className={cn("text-xl font-bold tracking-[0.08em]", collapsed && "lg:hidden")}>KKFC</span>
        <Button
          variant="ghost"
          size="icon-lg"
          aria-label="Toggle navigation"
          aria-controls="dashboard-nav"
          onClick={toggle}
          className="text-white hover:bg-white/10 hover:text-white"
        >
          {open ? <X className="size-5 lg:hidden" /> : null}
          <Menu className={cn("size-5", open && "max-lg:hidden")} />
        </Button>
      </div>

      <div
        className={cn(
          "flex-col lg:flex lg:min-h-0 lg:flex-1",
          open ? "flex max-h-[calc(100dvh-4rem)] border-t border-[#30445a]" : "hidden",
        )}
      >
        <nav
          id="dashboard-nav"
          aria-label="Dashboard"
          className={cn(
            "min-h-0 flex-1 overflow-y-auto pb-4",
            collapsed ? "px-3 lg:px-2.5 lg:pt-1.5" : "px-3",
          )}
        >
          {NAV_GROUPS.map((group) => (
            <NavSection
              key={group.label ?? "main"}
              {...group}
              pathname={pathname}
              collapsed={collapsed}
              onNavigate={close}
            />
          ))}
        </nav>
        <NavUser
          {...user}
          collapsed={collapsed}
          signingOut={logout.isPending}
          onSignOut={() => logout.mutate()}
        />
      </div>
    </aside>
  );
}
