import { cn } from "cn";
import { railFade } from "../../utils/railFade";

type NavSectionLabelProps = {
  children: string;
  id: string;
  collapsed: boolean;
};

// One box in both states, so the list never shifts: the text fades out and a
// divider fades in at the same height when the rail is collapsed.
export default function NavSectionLabel({ children, id, collapsed }: NavSectionLabelProps) {
  return (
    <p
      id={id}
      className="relative px-2.5 pt-5 pb-2 text-xs font-semibold tracking-[0.12em] whitespace-nowrap text-rail-muted uppercase"
    >
      <span className={railFade(collapsed)}>{children}</span>
      <span
        aria-hidden="true"
        className={cn(
          "absolute inset-x-1 top-[calc(50%+0.375rem)] h-px bg-rail-line opacity-0 transition-opacity duration-200 motion-reduce:transition-none",
          collapsed && "lg:opacity-100 lg:delay-100",
        )}
      />
    </p>
  );
}
