"use client";

import type { CSSProperties } from "react";
import { cn } from "cn";
import { useTheme } from "@/src/lib/theme";
import { ThemeSwitchTrack } from "./theme-switch";

// Standalone switch for pages without the navbar (sign-in, 403).
export function ThemeToggle({ className, style }: { className?: string; style?: CSSProperties }) {
  const { theme, toggle } = useTheme();

  return (
    <button
      type="button"
      role="switch"
      aria-checked={theme === "dark"}
      aria-label="Dark mode"
      title={theme === "dark" ? "Switch to light mode" : "Switch to dark mode"}
      onClick={toggle}
      className={cn(
        // A 44px-tall hit area around the 28px switch.
        "group grid h-11 cursor-pointer place-items-center rounded-full px-1.5 outline-none focus-visible:ring-2 focus-visible:ring-primary/40",
        className,
      )}
      style={style}
    >
      <ThemeSwitchTrack tone="page" size="md" />
    </button>
  );
}
