import { useForm } from "@tanstack/react-form";
import { useMutation } from "@tanstack/react-query";
import { useEffectEvent, useLayoutEffect, useState } from "react";
import { ApiError } from "@/src/lib/api-error";
import { loginSchema, type LoginUser } from "../schemas/loginSchema";
import type { LoginSession } from "../schemas/loginSessionSchema";
import { login } from "../services/auth.service";

/** Superadmins sign in in two steps; this is the second one. */
export type PinStep = {
  error: string | null;
  /** Locked out or no PIN set up: retrying here cannot succeed. */
  blocked: boolean;
};

// The PIN errors that keep the operator on the PIN step.
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
      return "This account has no PIN set up, so it can't sign in yet. Contact your system administrator.";
    default:
      return null;
  }
}

const errorMessage = (error: unknown) =>
  error instanceof Error ? error.message : "Unable to sign in. Please try again.";

export function useLogin(onSuccess: (session: LoginSession) => void) {
  const [serverError, setServerError] = useState<string | null>(null);
  const [pinStep, setPinStep] = useState<PinStep | null>(null);
  const loginMutation = useMutation({
    mutationFn: ({ credentials, pin }: { credentials: LoginUser; pin?: string }) => login(credentials, pin),
    retry: false,
    onSuccess,
  });

  const form = useForm({
    defaultValues: {
      username: "",
      password: "",
    },
    validators: {
      onChange: loginSchema,
    },
    onSubmit: async ({ value }) => {
      setServerError(null);
      try {
        await loginMutation.mutateAsync({ credentials: value });
      } catch (error) {
        if (error instanceof ApiError && error.code === "PIN_REQUIRED") {
          setPinStep({ error: null, blocked: false });
          return;
        }
        setServerError(errorMessage(error));
      }
    },
  });

  /** Resolves true when signed in, false when the PIN step shows an error instead. */
  async function submitPin(pin: string): Promise<boolean> {
    setPinStep({ error: null, blocked: false });
    try {
      await loginMutation.mutateAsync({ credentials: form.state.values, pin });
      return true;
    } catch (error) {
      // The password stopped working between steps: send them back to fix it.
      if (error instanceof ApiError && error.code === "INVALID_CREDENTIALS") {
        setPinStep(null);
        setServerError(error.message);
        return false;
      }
      const code = error instanceof ApiError ? error.code : undefined;
      setPinStep({
        error: pinErrorMessage(error) ?? errorMessage(error),
        blocked: code === "PIN_LOCKED" || code === "PIN_NOT_CONFIGURED",
      });
      return false;
    }
  }

  function cancelPin() {
    setPinStep(null);
    setServerError(null);
  }

  // Cache Components keeps this page alive (hidden) after navigating away, so clear
  // the credentials and "Opening dashboard…" state before it can be shown again.
  const resetOnHide = useEffectEvent(() => {
    form.reset();
    loginMutation.reset();
    setServerError(null);
    setPinStep(null);
  });
  useLayoutEffect(() => () => resetOnHide(), []);

  return {
    form,
    serverError,
    session: loginMutation.data,
    pinStep,
    pinPending: loginMutation.isPending,
    submitPin,
    cancelPin,
  };
}
