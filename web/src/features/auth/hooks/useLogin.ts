import { useForm } from "@tanstack/react-form";
import { useMutation } from "@tanstack/react-query";
import { useEffectEvent, useLayoutEffect, useState } from "react";
import { loginSchema } from "../schemas/loginSchema";
import type { LoginSession } from "../schemas/loginSessionSchema";
import { login } from "../services/auth.service";

export function useLogin(onSuccess: (session: LoginSession) => void) {
  const [serverError, setServerError] = useState<string | null>(null);
  const loginMutation = useMutation({ mutationFn: login, retry: false, onSuccess });

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
        await loginMutation.mutateAsync(value);
      } catch (error) {
        setServerError(error instanceof Error ? error.message : "Unable to sign in. Please try again.");
      }
    },
  });

  // Cache Components keeps this page alive (hidden) after navigating away, so clear
  // the credentials and "Opening dashboard…" state before it can be shown again.
  const resetOnHide = useEffectEvent(() => {
    form.reset();
    loginMutation.reset();
    setServerError(null);
  });
  useLayoutEffect(() => () => resetOnHide(), []);

  return {
    form,
    serverError,
    session: loginMutation.data,
  };
}
