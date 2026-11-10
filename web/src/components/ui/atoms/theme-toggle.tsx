"use client";

import type { CSSProperties } from "react";
import { cn } from "cn";
import { Button } from "@/components/ui/button";
import { useTheme } from "@/src/lib/theme";
import { ThemeIcon } from "./theme-icon";

// Standalone icon button for pages without the navbar (sign-in, 403).
export function ThemeToggle({ className, style }: { className?: string; style?: CSSProperties }) {
  const { theme, toggle } = useTheme();

  return (
    <Button
      type="button"
      variant="ghost"
      size="icon"
      aria-label="Dark mode"
      aria-pressed={theme === "dark"}
      title={theme === "dark" ? "Switch to light mode" : "Switch to dark mode"}
      onClick={toggle}
      className={cn(
        "size-11 cursor-pointer rounded-full text-ink-muted hover:bg-surface-hover hover:text-ink focus-visible:border-primary focus-visible:ring-primary/25",
        className,
      )}
      style={style}
    >
      <ThemeIcon />
    </Button>
  );
}
