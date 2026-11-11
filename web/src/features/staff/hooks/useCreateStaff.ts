import { useForm } from "@tanstack/react-form";
import { useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { usePin } from "@/src/features/pin/hooks/usePin";
import { ApiError } from "@/src/lib/api-error";
import { createStaffSchema, type CreateStaffInput, type CreateStaffValues } from "../schemas/createStaffSchema";
import type { User } from "../schemas/userSchema";
import { createUser } from "../services/users.service";

const EMPTY: CreateStaffValues = { first_name: "", last_name: "", username: "", role: "", password: "" };

function createErrorMessage(error: unknown, username: string): string {
  if (!(error instanceof ApiError)) return "Unable to create the account. Please try again.";
  if (error.code === "USERNAME_ALREADY_EXISTS") return `The username "${username}" is already taken. Choose another.`;
  if (error.status === 401) return "Your session has expired. Sign in again to continue.";
  if (error.status === 403) return "You don't have permission to create this account.";
  return error.message;
}

export function useCreateStaff(onCreated: (user: User) => void) {
  const { withPin } = usePin();
  const queryClient = useQueryClient();
  const [serverError, setServerError] = useState<string | null>(null);

  const form = useForm({
    defaultValues: EMPTY,
    validators: { onChange: createStaffSchema },
    onSubmit: async ({ value, formApi }) => {
      setServerError(null);
      const input = createStaffSchema.parse(value) as CreateStaffInput;

      try {
        const user = await withPin((pin) => createUser(input, pin), {
          title: "Confirm new account",
          description: `Enter your PIN to create ${input.first_name} ${input.last_name}'s account.`,
        });
        if (!user) return; // PIN prompt cancelled: keep the form as it is.

        await queryClient.invalidateQueries({ queryKey: ["users"] });
        formApi.reset();
        onCreated(user);
      } catch (error) {
        setServerError(createErrorMessage(error, input.username));
      }
    },
  });

  function reset() {
    form.reset();
    setServerError(null);
  }

  return { form, serverError, reset };
}
