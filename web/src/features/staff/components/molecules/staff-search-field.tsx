import { Search, X } from "lucide-react";

type StaffSearchFieldProps = {
  value: string;
  onChange: (value: string) => void;
};

// DESIGN.md › Search Field: leading lens, trailing clear.
export default function StaffSearchField({ value, onChange }: StaffSearchFieldProps) {
  return (
    <div className="relative w-full sm:w-auto sm:min-w-72 sm:flex-1 md:max-w-sm">
      <Search
        aria-hidden="true"
        className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-ink-muted"
      />
      <input
        type="search"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder="Search name or username"
        aria-label="Search name or username"
        className="h-10 w-full rounded-lg border border-hairline bg-field pr-9 pl-9 text-base text-ink caret-primary outline-none placeholder:text-ink-muted/80 focus-visible:border-primary focus-visible:ring-2 focus-visible:ring-primary/15 [&::-webkit-search-cancel-button]:hidden"
      />
      {value ? (
        <button
          type="button"
          onClick={() => onChange("")}
          aria-label="Clear search"
          className="absolute top-1/2 right-1.5 grid size-7 -translate-y-1/2 cursor-pointer place-items-center rounded-md text-ink-muted outline-none hover:bg-ink/6 hover:text-ink focus-visible:ring-2 focus-visible:ring-primary/40"
        >
          <X aria-hidden="true" className="size-4" />
        </button>
      ) : null}
    </div>
  );
}
