import { useLayoutEffect, useRef, useState } from "react";
import { LogOut } from "lucide-react";
import { cn } from "cn";
import { Avatar } from "@/src/components/ui/atoms/avatar";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuGroup,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { formatRole } from "../../utils/formatRole";
import { railFade } from "../../utils/railFade";

export type NavUserProps = {
  name: string;
  role: string;
  username: string;
  collapsed: boolean;
  signingOut: boolean;
  onSignOut: () => void;
};

export default function NavUser({ name, role, username, collapsed, signingOut, onSignOut }: NavUserProps) {
  const [menuOpen, setMenuOpen] = useState(false);
  // Set when "Sign out" is chosen. The sign-out waits until the menu has fully
  // closed: a popup still fading out when the page is hidden never finishes, and
  // reappears (grabbing focus) the next time the dashboard is shown.
  const leaving = useRef(false);

  // The account menu is transient: close it when the page is hidden.
  useLayoutEffect(() => () => {
    setMenuOpen(false);
    leaving.current = false;
  }, []);

  return (
    <div className="p-2">
      <DropdownMenu
        open={menuOpen}
        onOpenChange={setMenuOpen}
        onOpenChangeComplete={(open) => {
          if (!open && leaving.current) onSignOut();
        }}
      >
        <DropdownMenuTrigger
          aria-label={`Account menu for ${name}`}
          disabled={signingOut}
          aria-busy={signingOut}
          title={collapsed ? `${name} · ${formatRole(role)}` : undefined}
          className={cn(
            // px-2 puts the avatar's centre on the collapsed rail's centre line.
            "flex w-full items-center gap-3 rounded-md px-2 py-2 text-left whitespace-nowrap transition-colors outline-none hover:bg-white/10 disabled:cursor-progress disabled:opacity-70 focus-visible:ring-2 focus-visible:ring-white/60 data-popup-open:bg-white/10",
          )}
        >
          <Avatar name={name} />
          <span className={cn("min-w-0 leading-tight", railFade(collapsed))}>
            <span className="block truncate text-sm font-semibold">{name}</span>
            <span className="block truncate text-xs text-rail-muted">
              {signingOut ? "Signing out…" : formatRole(role)}
            </span>
          </span>
        </DropdownMenuTrigger>

        {/* Collapsed rail: open beside the avatar instead of over the rail's edge. */}
        <DropdownMenuContent
          side={collapsed ? "right" : "top"}
          align={collapsed ? "end" : "start"}
          sideOffset={8}
          finalFocus={() => !leaving.current}
          className={cn("min-w-56 rounded-xl p-1.5", collapsed && "w-56")}
        >
          <DropdownMenuGroup>
            <DropdownMenuLabel className="px-2 pt-1.5 pb-2">
              <span className="block text-xs text-ink-muted">Signed in as</span>
              <span className="block truncate text-sm font-medium text-ink">{username}</span>
            </DropdownMenuLabel>
          </DropdownMenuGroup>
          <DropdownMenuSeparator className="-mx-1.5 my-1" />
          <DropdownMenuItem
            className="h-9 gap-2.5 rounded-lg px-2 text-ink focus:bg-surface-hover focus:text-ink [&_svg]:text-ink-muted"
            onClick={() => {
              leaving.current = true;
            }}
          >
            <LogOut />
            Sign out
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    </div>
  );
}
