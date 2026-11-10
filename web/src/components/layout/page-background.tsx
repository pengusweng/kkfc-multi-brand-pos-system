import { ReactNode } from "react";
import { cn } from "cn";

export default function PageBackground({
  children,
  className,
}: {
  children?: ReactNode;
  className?: string;
}) {
  return (
    <main className={cn("relative isolate flex min-h-dvh min-w-0 flex-1 items-start justify-center overflow-x-clip bg-[radial-gradient(ellipse_at_center,var(--page-from),var(--page-to))] px-4 py-8 text-page-text sm:p-8 lg:items-center", className)}>
      <svg
        aria-hidden="true"
        viewBox="0 0 217 129"
        className="pointer-events-none absolute top-0 left-0 -z-10 h-auto w-48 max-w-full lg:w-80"
      >
        <path
          d="M0 0H217C175 55 115 56 61 70C25 81 11 103 0 129Z"
          fill="var(--wave-1)"
        />
        <path
          d="M0 0H143C96 40 49 37 0 56Z"
          fill="var(--wave-2)"
        />
      </svg>
      <svg
        aria-hidden="true"
        viewBox="345 393 441 212"
        className="pointer-events-none absolute right-0 bottom-0 -z-10 h-auto w-64 max-w-full lg:w-100"
      >
        <path
          d="M345 605C402 551 435 542 507 553C644 578 659 449 786 393V605Z"
          fill="var(--wave-1)"
        />
        <path
          d="M444 605C524 553 579 555 624 557C692 559 739 505 786 485V605Z"
          fill="var(--wave-2)"
        />
      </svg>
      {children}
    </main>
  )
}
