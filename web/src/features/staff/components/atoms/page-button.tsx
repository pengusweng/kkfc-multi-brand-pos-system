import type { ComponentProps } from "react";

type PageButtonProps = ComponentProps<"button"> & {
  /** Filled: the current page. Outlined: Prev/Next. Plain: other page numbers. */
  variant?: "plain" | "outlined" | "current";
};

const VARIANT = {
  plain: "text-ink hover:bg-surface-hover",
  outlined: "border border-hairline text-ink hover:bg-surface-hover",
  current: "bg-ink text-card",
};

export default function PageButton({ variant = "plain", className = "", ...props }: PageButtonProps) {
  return (
    <button
      type="button"
      className={`inline-flex h-9 min-w-9 cursor-pointer items-center justify-center rounded-lg px-2.5 text-sm font-semibold tabular-nums transition-colors outline-none focus-visible:ring-2 focus-visible:ring-primary/40 disabled:cursor-not-allowed disabled:opacity-40 ${VARIANT[variant]} ${className}`}
      {...props}
    />
  );
}
