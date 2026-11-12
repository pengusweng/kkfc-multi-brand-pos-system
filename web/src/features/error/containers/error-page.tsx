"use client";

import { useCallback, useEffect, useLayoutEffect, useTransition } from "react";
import { CircleAlert, CloudOff, WifiOff, type LucideIcon } from "lucide-react";
import PageBackground from "@/src/components/layout/page-background";
import { ThemeToggle } from "@/src/components/ui/atoms/theme-toggle";
import LoginSide from "@/src/features/auth/components/login-side";
import { restoreTheme } from "@/src/lib/theme";
import RetryButton from "../components/retry-button";
import { useOnline } from "../hooks/useOnline";
import { describeError, type ErrorKind } from "../utils/describeError";

const ICONS: Record<ErrorKind, LucideIcon> = {
  offline: WifiOff,
  unreachable: CloudOff,
  unexpected: CircleAlert,
};

export type ErrorPageProps = {
  error: unknown;
  retry: () => void;
};

// Same frame as the 403 page: the brand rail beside a single message and one
// way forward. The footer carries the error's digest so an admin can find it in
// the server logs.
export default function ErrorPage({ error, retry }: ErrorPageProps) {
  const [pending, startTransition] = useTransition();
  const tryAgain = useCallback(() => startTransition(retry), [retry]);
  const online = useOnline(tryAgain);
  const { kind, title, body, digest } = describeError(error, online);
  const Icon = ICONS[kind];

  useLayoutEffect(restoreTheme, []);

  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <PageBackground>
      <title>{`${title} | KKFC Management`}</title>
      <ThemeToggle className="absolute top-3 right-3 z-10 sm:top-5 sm:right-5" />
      <section
        aria-labelledby="error-title"
        className="grid w-full max-w-md overflow-hidden rounded-[1rem] border border-hairline bg-card selection:bg-primary/15 selection:text-ink lg:min-h-140 lg:max-w-240 lg:grid-cols-[20rem_minmax(0,1fr)]"
      >
        <LoginSide />

        <div className="w-full max-w-132 self-center justify-self-center px-6 py-8 lg:p-12">
          <Icon aria-hidden="true" strokeWidth={1.75} className="size-9 text-primary-ink" />

          <div role="alert">
            <h1
              id="error-title"
              className="mt-6 text-2xl leading-tight font-semibold tracking-tight text-balance text-ink sm:text-3xl"
            >
              {title}
            </h1>
            <p className="mt-3 text-base leading-7 text-pretty text-ink-muted">{body}</p>
          </div>

          <RetryButton pending={pending} onRetry={tryAgain} className="mt-8" />

          <div className="mt-8 flex items-start justify-between gap-6 border-t border-hairline pt-6 text-sm leading-6 text-ink-muted">
            <p className="max-w-64">
              Still not working? Contact your company administrator
              {digest ? " and share this reference." : "."}
            </p>
            {digest && (
              <span
                aria-label={`Error reference ${digest}`}
                title="Error reference"
                className="shrink-0 font-medium tabular-nums select-all"
              >
                {digest}
              </span>
            )}
          </div>
        </div>
      </section>
    </PageBackground>
  );
}
