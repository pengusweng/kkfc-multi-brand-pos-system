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

export type NavUserProps = {
  name: string;
  role: string;
  collapsed: boolean;
  signingOut: boolean;
  onSignOut: () => void;
};

export default function NavUser({ name, role, collapsed, signingOut, onSignOut }: NavUserProps) {
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
    <div className="border-t border-[#30445a] p-2">
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
            "flex w-full items-center gap-3 rounded-md px-1.5 py-2 text-left transition-colors outline-none hover:bg-white/10 disabled:cursor-progress disabled:opacity-70 focus-visible:ring-2 focus-visible:ring-white/60 data-popup-open:bg-white/10",
            collapsed && "lg:justify-center lg:px-0",
          )}
        >
          <Avatar name={name} />
          <span className={cn("min-w-0 leading-tight", collapsed && "lg:sr-only")}>
            <span className="block truncate text-sm font-semibold">{name}</span>
            <span className="block truncate text-xs text-[#c7d9ed]">
              {signingOut ? "Signing out…" : formatRole(role)}
            </span>
          </span>
        </DropdownMenuTrigger>

        <DropdownMenuContent side="top" align="start" className="w-56" finalFocus={() => !leaving.current}>
          <DropdownMenuGroup>
            <DropdownMenuLabel>
              <span className="block truncate font-semibold text-foreground">{name}</span>
              {formatRole(role)}
            </DropdownMenuLabel>
          </DropdownMenuGroup>
          <DropdownMenuSeparator />
          {/* Closes the menu right away, so it's never left open in the hidden dashboard. */}
          <DropdownMenuItem
            variant="destructive"
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
