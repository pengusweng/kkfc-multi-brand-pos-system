import { ChevronRight } from "lucide-react";

export default function ViewButton({ label, onClick }: { label: string; onClick?: () => void }) {
  return (
    <button
      type="button"
      onClick={onClick}
      aria-label={label}
      className="inline-flex h-8 cursor-pointer items-center gap-1 rounded-md pr-1.5 pl-2.5 font-semibold text-ink transition-colors outline-none hover:bg-ink/6 focus-visible:ring-2 focus-visible:ring-primary/40 active:bg-ink/10 [&_svg]:text-ink-muted"
    >
      View
      <ChevronRight aria-hidden="true" className="size-4" strokeWidth={2.25} />
    </button>
  );
}
