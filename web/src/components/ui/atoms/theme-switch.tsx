import { Moon, Sun } from "lucide-react";
import { cn } from "cn";

type Tone = "page" | "rail";

const TONES: Record<Tone, { track: string; knob: string }> = {
  // On the cream/ink page: a quiet hairline track by day, terracotta at night.
  page: {
    track:
      "bg-hairline ring-1 ring-inset ring-ink/10 group-hover:bg-[color-mix(in_oklab,var(--hairline),var(--ink)_8%)] dark:bg-primary dark:ring-0 dark:group-hover:bg-[color-mix(in_oklab,var(--primary),white_8%)]",
    knob: "bg-field text-primary-ink shadow-[0_1px_2px_oklch(0.2_0.03_255/0.22),0_2px_6px_-1px_oklch(0.2_0.03_255/0.18)] dark:bg-rail-pill dark:text-rail-pill-ink",
  },
  // On the navy rail: a translucent white track by day, terracotta at night.
  rail: {
    track: "bg-white/15 group-hover:bg-white/22 dark:bg-primary dark:group-hover:bg-[color-mix(in_oklab,var(--primary),white_8%)]",
    knob: "bg-white text-primary shadow-[0_1px_2px_rgb(0_0_0/0.3)] dark:bg-rail-pill dark:text-rail-pill-ink",
  },
};

// Pressing stretches the knob toward where it's about to go (like a finger
// pushing it); in dark mode the travel shrinks by the same amount so the knob
// keeps hugging the right edge while stretched.
const SIZES = {
  sm: {
    track: "h-5 w-9 p-0.5",
    knob: "h-4 w-4 group-active:w-5 dark:translate-x-4 dark:group-active:translate-x-3",
    icon: "size-2.5",
  },
  md: {
    track: "h-7 w-12 p-0.5",
    knob: "h-6 w-6 group-active:w-7.5 dark:translate-x-5 dark:group-active:translate-x-3.5",
    icon: "size-3.5",
  },
};

// The visual half of the theme switch: a track with a knob that slides right
// for dark and carries a sun or a moon. Position and icon come from `dark:`
// classes, so the switch is correct on first paint, before React knows the
// theme. Wrap it in an element with `group` for the hover and press states.
//
// The knob decelerates into place (380ms) while the page colors ease over in
// globals.css (420ms), so knob and page settle together as one gesture.
// `data-theme-switch` keeps these transitions running during the page fade.
export function ThemeSwitchTrack({
  tone = "page",
  size = "md",
  className,
}: {
  tone?: Tone;
  size?: keyof typeof SIZES;
  className?: string;
}) {
  const motion = "duration-380 ease-out-quart motion-reduce:duration-150";
  const iconLayer = cn(
    "absolute transition-[scale,rotate,opacity] motion-reduce:transition-opacity",
    motion,
    SIZES[size].icon,
  );

  return (
    <span
      aria-hidden="true"
      data-theme-switch
      className={cn(
        "inline-flex shrink-0 items-center rounded-full transition-[background-color,box-shadow]",
        motion,
        TONES[tone].track,
        SIZES[size].track,
        className,
      )}
    >
      <span
        className={cn(
          "relative grid place-items-center rounded-full transition-[translate,width,background-color,color] motion-reduce:transition-[background-color,color]",
          motion,
          TONES[tone].knob,
          SIZES[size].knob,
        )}
      >
        {/* The sun sets (turns and sinks away) as the moon rises in its place. */}
        <Sun strokeWidth={2.25} className={cn(iconLayer, "dark:scale-50 dark:-rotate-90 dark:opacity-0")} />
        <Moon
          strokeWidth={2.25}
          className={cn(iconLayer, "scale-50 rotate-90 opacity-0 dark:scale-100 dark:rotate-0 dark:opacity-100")}
        />
      </span>
    </span>
  );
}
