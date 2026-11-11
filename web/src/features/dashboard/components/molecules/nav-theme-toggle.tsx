"use client";

import { ThemeSwitchTrack } from "@/src/components/ui/atoms/theme-switch";
import { useTheme } from "@/src/lib/theme";
import { railFade } from "../../utils/railFade";

// A switch row in the rail's footer. The switch sits where the nav icons do,
// centred in the 64px collapsed rail, so its state stays visible with the
// label faded out.
export default function NavThemeToggle({ collapsed }: { collapsed: boolean }) {
  const { theme, toggle } = useTheme();

  return (
    <div className="px-3 pt-2">
      <button
        type="button"
        role="switch"
        aria-checked={theme === "dark"}
        onClick={toggle}
        title={collapsed ? (theme === "dark" ? "Dark mode on" : "Dark mode off") : undefined}
        className="group flex h-9 w-full cursor-pointer items-center gap-2.5 rounded-md px-0.5 text-left text-sm font-semibold whitespace-nowrap text-white transition-colors duration-200 outline-none hover:bg-white/10 focus-visible:ring-2 focus-visible:ring-white/60"
      >
        <ThemeSwitchTrack tone="rail" size="sm" />
        <span className={railFade(collapsed)}>Dark mode</span>
      </button>
    </div>
  );
}
