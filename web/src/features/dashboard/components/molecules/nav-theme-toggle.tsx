"use client";

import { ThemeIcon } from "@/src/components/ui/atoms/theme-icon";
import { useTheme } from "@/src/lib/theme";
import { railFade } from "../../utils/railFade";

// Sits with the nav links and behaves like one: same box, same hover, and the
// label fades out with the others when the rail collapses to icons.
export default function NavThemeToggle({ collapsed }: { collapsed: boolean }) {
  const { theme, toggle } = useTheme();
  const label = theme === "dark" ? "Light mode" : "Dark mode";

  return (
    <div className="px-3 pt-2">
      <button
        type="button"
        onClick={toggle}
        aria-pressed={theme === "dark"}
        aria-label="Dark mode"
        title={collapsed ? label : undefined}
        className="flex h-9 w-full cursor-pointer items-center gap-2.5 rounded-md px-2.5 text-left text-sm font-semibold whitespace-nowrap text-white transition-colors duration-200 outline-none hover:bg-white/10 focus-visible:ring-2 focus-visible:ring-white/60"
      >
        <ThemeIcon />
        {/* Both labels render so the right one shows before hydration; CSS picks it. */}
        <span className={railFade(collapsed)}>
          <span className="dark:hidden">Dark mode</span>
          <span className="hidden dark:inline">Light mode</span>
        </span>
      </button>
    </div>
  );
}
