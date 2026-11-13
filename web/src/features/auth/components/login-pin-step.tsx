"use client";

import { useEffect, useRef, useState } from "react";
import { CircleAlert, LoaderCircle, UserRound } from "lucide-react";
import { Button } from "@/components/ui/button";
import PinInput, { PIN_LENGTH } from "@/src/features/pin/components/molecules/pin-input";
import type { PinStep } from "../hooks/useLogin";

type LoginPinStepProps = {
  username: string;
  step: PinStep;
  pending: boolean;
  redirecting: boolean;
  onSubmit: (pin: string) => Promise<boolean>;
  onBack: () => void;
};

// The second sign-in step for superadmins: same card, same rhythm as the
// credentials form, so it reads as one flow rather than an interruption.
export default function LoginPinStep({ username, step, pending, redirecting, onSubmit, onBack }: LoginPinStepProps) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [pin, setPin] = useState("");
  // Typing a new PIN dismisses the last attempt's error, as the PIN modal does.
  const [edited, setEdited] = useState(false);
  const error = edited ? null : step.error;
  const busy = pending || redirecting;

  useEffect(() => {
    inputRef.current?.focus();
  }, []);

  async function submit(value: string) {
    if (busy || step.blocked || value.length !== PIN_LENGTH) return;
    setEdited(false);
    if (await onSubmit(value)) return;
    setPin("");
    requestAnimationFrame(() => inputRef.current?.focus());
  }

  return (
    <div className="motion-safe:animate-page-in">
      <header>
        <h1 id="login-title" className="text-3xl leading-tight font-semibold tracking-[-0.01em] text-ink">
          Enter your PIN
        </h1>
        <p className="mt-2 text-base leading-6 text-pretty text-ink-muted">
          Superadmin accounts also need their 4-digit PIN to sign in.
        </p>
      </header>

      <form
        noValidate
        aria-label="PIN"
        className="mt-8 flex flex-col gap-5"
        onSubmit={(event) => {
          event.preventDefault();
          void submit(pin);
        }}
      >
        <div className="flex min-h-14 items-center gap-3 rounded-[10px] border border-hairline bg-field py-1.5 pr-1.5 pl-3.5">
          <UserRound aria-hidden="true" className="size-5 shrink-0 text-ink-muted" />
          <p className="min-w-0 flex-1 truncate text-base text-ink">
            <span className="sr-only">Signing in as</span> {username.trim()}
          </p>
          <Button
            type="button"
            variant="ghost"
            disabled={busy}
            onClick={onBack}
            aria-label="Change account"
            className="h-11 cursor-pointer px-3 text-sm font-semibold text-ink-muted hover:bg-surface-hover hover:text-ink"
          >
            Change
          </Button>
        </div>

        <PinInput
          ref={inputRef}
          stretch
          value={pin}
          onChange={(value) => {
            setPin(value);
            setEdited(true);
          }}
          onComplete={(value) => void submit(value)}
          invalid={Boolean(error)}
          disabled={busy || step.blocked}
          describedBy={error ? "login-pin-error" : undefined}
        />

        {error && (
          <p
            id="login-pin-error"
            role="alert"
            className="flex items-start gap-2.5 rounded-lg bg-destructive/8 px-3 py-2.5 text-sm leading-5 text-danger-ink motion-safe:animate-rise"
          >
            <CircleAlert aria-hidden="true" className="mt-px size-4 shrink-0 text-destructive" />
            {error}
          </p>
        )}

        <Button
          type="submit"
          disabled={busy || step.blocked || pin.length !== PIN_LENGTH}
          aria-busy={busy}
          className="mt-1 h-12 w-full cursor-pointer text-base font-semibold disabled:opacity-80"
        >
          {busy && <LoaderCircle aria-hidden="true" className="size-5 animate-spin" />}
          {redirecting ? "Opening dashboard…" : pending ? "Checking PIN…" : "Sign In"}
        </Button>
      </form>
    </div>
  );
}
