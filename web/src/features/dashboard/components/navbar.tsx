"use client";

import { useLayoutEffect, useState } from "react";
import { usePathname } from "next/navigation";
import { Menu, X } from "lucide-react";
import { cn } from "cn";
import { Button } from "@/components/ui/button";
import NavSection from "./molecules/nav-section";
import NavUser, { type NavUserProps } from "./molecules/nav-user";
import { railFade } from "../utils/railFade";
import { NAV_GROUPS } from "../utils/navItems";
import { useLogout } from "@/src/features/auth/hooks/useLogout";
import { RailTransition, WordmarkTransition } from "@/src/components/layout/shared-transitions";

const DESKTOP_QUERY = "(min-width: 64rem)";

export default function Navbar({ user }: { user: Pick<NavUserProps, "name" | "role" | "username"> }) {
  const pathname = usePathname();
  const [open, setOpen] = useState(false);
  const [collapsed, setCollapsed] = useState(false);
  const close = () => setOpen(false);
  const logout = useLogout();

  // Close the mobile menu when the page is hidden so it isn't open on return.
  useLayoutEffect(() => () => setOpen(false), []);

  // Mobile: the burger opens the dropdown menu. Desktop: it collapses the sidebar to icons.
  const toggle = () => {
    if (window.matchMedia(DESKTOP_QUERY).matches) setCollapsed((value) => !value);
    else setOpen((value) => !value);
  };

  return (
    <RailTransition>
    <aside
      className={cn(
        "sticky top-0 z-40 flex shrink-0 flex-col overflow-hidden bg-[rgb(25,41,62)] text-white transition-[width] duration-300 ease-drawer motion-reduce:transition-none lg:h-dvh",
        collapsed ? "lg:w-16" : "lg:w-60",
      )}
    >
      {/* The burger sits 14px in from the rail's right edge, which also centres it
          in the 64px collapsed rail, so it rides the edge instead of jumping. */}
      <div className="relative flex h-16 shrink-0 items-center justify-end px-3.5">
        <WordmarkTransition>
          <span
            className={cn(
              "absolute top-1/2 left-4 inline-block -translate-y-1/2 text-xl font-bold tracking-[0.12em]",
              railFade(collapsed),
            )}
          >
            KKFC
          </span>
        </WordmarkTransition>
        <Button
          variant="ghost"
          size="icon-lg"
          aria-label="Toggle navigation"
          aria-controls="dashboard-nav"
          onClick={toggle}
          className="text-white hover:bg-white/10 hover:text-white"
        >
          {/* Menu and X cross-rotate on mobile; desktop always shows the menu icon. */}
          <span className="relative size-5">
            <Menu
              className={cn(
                "absolute inset-0 size-5 transition duration-300 ease-drawer motion-reduce:transition-none",
                open && "max-lg:scale-50 max-lg:rotate-90 max-lg:opacity-0",
              )}
            />
            <X
              className={cn(
                "absolute inset-0 size-5 transition duration-300 ease-drawer motion-reduce:transition-none lg:hidden",
                !open && "scale-50 -rotate-90 opacity-0",
              )}
            />
          </span>
        </Button>
      </div>

      {/* Mobile: the panel slides open by animating its grid row from 0fr to 1fr.
          `invisible` (applied once the close finishes) keeps it out of the tab order. */}
      <div
        className={cn(
          "grid transition-[grid-template-rows,opacity,visibility] duration-300 ease-drawer motion-reduce:transition-none lg:visible lg:flex lg:min-h-0 lg:flex-1 lg:flex-col lg:opacity-100",
          open ? "visible grid-rows-[1fr] opacity-100" : "invisible grid-rows-[0fr] opacity-0",
        )}
      >
        <div className="flex max-h-[calc(100dvh-4rem)] min-h-0 flex-col overflow-hidden border-t border-[#30445a] lg:max-h-none lg:flex-1 lg:border-t-0">
        <nav
          id="dashboard-nav"
          aria-label="Dashboard"
          className="min-h-0 flex-1 overflow-x-hidden overflow-y-auto px-3 pb-4"
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
      </div>
    </aside>
    </RailTransition>
  );
}
