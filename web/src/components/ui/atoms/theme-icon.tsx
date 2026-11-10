import { Moon, Sun } from "lucide-react";
import { cn } from "cn";

// Shows the theme a click switches to: a moon in light mode, a sun in dark.
// The swap is pure CSS (`dark:`), so it is right on first paint, before React
// knows the theme. The two icons cross-rotate like the navbar's menu/close pair.
export function ThemeIcon({ className }: { className?: string }) {
  const layer = "absolute inset-0 size-full transition duration-300 ease-drawer motion-reduce:transition-none";
  return (
    <span aria-hidden="true" className={cn("relative size-5 shrink-0", className)}>
      <Moon strokeWidth={1.75} className={cn(layer, "dark:scale-50 dark:-rotate-90 dark:opacity-0")} />
      <Sun strokeWidth={1.75} className={cn(layer, "scale-50 rotate-90 opacity-0 dark:scale-100 dark:rotate-0 dark:opacity-100")} />
    </span>
  );
}
