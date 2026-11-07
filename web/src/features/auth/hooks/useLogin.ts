import { useForm } from "@tanstack/react-form";
import { useMutation } from "@tanstack/react-query";
import { useState } from "react";
import { loginSchema } from "../schemas/loginSchema";
import { login } from "../services/auth.service";

export function useLogin() {
  const [serverError, setServerError] = useState<string | null>(null);
  const loginMutation = useMutation({ mutationFn: login, retry: false });

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

  return {
    form,
    serverError,
    session: loginMutation.data,
  };
}
