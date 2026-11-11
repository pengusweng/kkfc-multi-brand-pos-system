"use client";

import { useRef, useState, type RefObject } from "react";
import { CircleAlert, LoaderCircle, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { ApiError } from "@/src/lib/api-error";
import PinInput, { PIN_LENGTH } from "../molecules/pin-input";

export type PinRequest = {
  id: number;
  title?: string;
  description?: string;
  run: (pin: string) => Promise<unknown>;
  resolve: (value: unknown) => void;
  reject: (error: unknown) => void;
};

// Errors that mean "this PIN attempt failed", so the prompt stays open.
// Everything else belongs to the caller and closes the prompt.
function pinErrorMessage(error: unknown): string | null {
  if (!(error instanceof ApiError)) return null;
  switch (error.code) {
    case "INVALID_PIN":
      return "Incorrect PIN. Try again.";
    case "PIN_LOCKED": {
      const minutes = Math.max(1, Math.ceil((error.retryAfter ?? 60) / 60));
      return `Too many incorrect attempts. Try again in ${minutes} minute${minutes === 1 ? "" : "s"}.`;
    }
    case "PIN_NOT_CONFIGURED":
      return "You haven't set up a PIN yet. Set one up before making changes.";
    default:
      return null;
  }
}

const SURFACE =
  "shadow-[0_8px_24px_rgba(25,41,62,0.14),0_2px_8px_rgba(25,41,62,0.08)] dark:shadow-none dark:ring-1 dark:ring-hairline";

type PinModalProps = {
  request: PinRequest | null;
  open: boolean;
  onFinish: () => void;
};

export default function PinModal({ request, open, onFinish }: PinModalProps) {
  const inputRef = useRef<HTMLInputElement>(null);
  return (
    <Dialog
      open={open}
      onOpenChange={(next) => {
        if (!next && request) {
          request.resolve(undefined);
          onFinish();
        }
      }}
    >
      <DialogContent
        showCloseButton={false}
        initialFocus={inputRef}
        className={`flex flex-col gap-0 overflow-hidden rounded-xl bg-card p-0 text-ink ring-0 sm:max-w-sm ${SURFACE}`}
      >
        {/* Keyed so every request starts with an empty PIN and no error. */}
        {request ? <PinForm key={request.id} request={request} onFinish={onFinish} inputRef={inputRef} /> : null}
      </DialogContent>
    </Dialog>
  );
}

type PinFormProps = {
  request: PinRequest;
  onFinish: () => void;
  inputRef: RefObject<HTMLInputElement | null>;
};

function PinForm({ request, onFinish, inputRef }: PinFormProps) {
  const [pin, setPin] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [blocked, setBlocked] = useState(false);

  async function submit(value: string) {
    if (busy || blocked || value.length !== PIN_LENGTH) return;
    setBusy(true);
    setError(null);
    try {
      const result = await request.run(value);
      request.resolve(result);
      onFinish();
    } catch (err) {
      const message = pinErrorMessage(err);
      if (!message) {
        request.reject(err);
        onFinish();
        return;
      }
      setError(message);
      setPin("");
      const code = err instanceof ApiError ? err.code : undefined;
      if (code === "PIN_LOCKED" || code === "PIN_NOT_CONFIGURED") setBlocked(true);
      else requestAnimationFrame(() => inputRef.current?.focus());
    } finally {
      setBusy(false);
    }
  }

  return (
    <form
      noValidate
      onSubmit={(e) => {
        e.preventDefault();
        void submit(pin);
      }}
    >
      <DialogHeader className="flex-row items-center justify-between gap-4 border-b border-hairline py-3 pr-3 pl-6">
        <DialogTitle className="text-base font-semibold text-ink">{request.title ?? "Enter your PIN"}</DialogTitle>
        <DialogClose
          disabled={busy}
          render={<Button variant="ghost" size="icon-lg" className="size-10 text-ink-muted hover:text-ink" />}
        >
          <X aria-hidden="true" className="size-5" />
          <span className="sr-only">Cancel</span>
        </DialogClose>
      </DialogHeader>

      <div className="flex flex-col gap-5 px-6 pt-5 pb-6">
        <DialogDescription className="text-sm leading-relaxed text-ink-muted">
          {request.description ?? "Confirm this action with your 4-digit PIN."}
        </DialogDescription>

        <PinInput
          ref={inputRef}
          value={pin}
          onChange={(value) => {
            setPin(value);
            if (error && !blocked) setError(null);
          }}
          onComplete={(value) => void submit(value)}
          invalid={Boolean(error)}
          disabled={busy || blocked}
          describedBy={error ? "pin-error" : undefined}
        />

        {error ? (
          <p
            id="pin-error"
            role="alert"
            className="flex items-start gap-2.5 rounded-lg bg-destructive/8 px-3 py-2.5 text-sm leading-5 text-danger-ink"
          >
            <CircleAlert aria-hidden="true" className="mt-px size-4 shrink-0 text-destructive" />
            {error}
          </p>
        ) : null}
      </div>

      <DialogFooter className="mx-0 mb-0 border-hairline bg-transparent px-6 py-4">
        <DialogClose
          disabled={busy}
          render={<Button type="button" variant="outline" size="lg" className="h-10 px-4 font-semibold" />}
        >
          Cancel
        </DialogClose>
        <Button
          type="submit"
          size="lg"
          className="h-10 px-4 font-semibold"
          disabled={busy || blocked || pin.length !== PIN_LENGTH}
          aria-busy={busy}
        >
          {busy ? <LoaderCircle aria-hidden="true" className="animate-spin" /> : null}
          {busy ? "Checking…" : "Confirm"}
        </Button>
      </DialogFooter>
    </form>
  );
}
