import { ReactNode } from "react";

export default function PageBackground({
  children,
}: {
  children: ReactNode;
}) {
  return (
    <main className="relative isolate flex min-h-svh flex-1 items-center justify-center overflow-hidden bg-[radial-gradient(ellipse_at_center,#fdf7f1,#fbeee2)] p-6 text-slate-800">
      <svg
        aria-hidden="true"
        viewBox="0 0 786 605"
        preserveAspectRatio="none"
        className="pointer-events-none absolute inset-0 -z-10 h-full w-full"
      >
        <path
          d="M0 0H217C175 55 115 56 61 70C25 81 11 103 0 129Z"
          fill="#fce6d6"
        />
        <path
          d="M0 0H143C96 40 49 37 0 56Z"
          fill="#fbdac0"
        />
        <path
          d="M345 605C402 551 435 542 507 553C644 578 659 449 786 393V605Z"
          fill="#fce6d6"
        />
        <path
          d="M444 605C524 553 579 555 624 557C692 559 739 505 786 485V605Z"
          fill="#fbdac0"
        />
      </svg>
      {children}
    </main>
  )
}