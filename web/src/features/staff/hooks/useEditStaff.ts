import { useForm } from "@tanstack/react-form";
import { useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { usePin } from "@/src/features/pin/hooks/usePin";
import { ApiError } from "@/src/lib/api-error";
import { editStaffSchema, type EditStaffValues, type UpdateStaffInput } from "../schemas/editStaffSchema";
import type { User } from "../schemas/userSchema";
import { updateUser } from "../services/users.service";
import type { StaffMember } from "../utils/staff";

function editErrorMessage(error: unknown, username: string | undefined): string {
  if (!(error instanceof ApiError)) return "Unable to save the changes. Please try again.";
  if (error.code === "USERNAME_ALREADY_EXISTS" || error.code === "DUPLICATE_RESOURCE")
    return `The username "${username}" is already taken. Choose another.`;
  if (error.code === "USER_NOT_FOUND") return "This account is inactive or no longer exists.";
  if (error.code === "CANNOT_MODIFY_PRIVILEGED_ACCOUNT") return "Only a superadmin can edit this account.";
  if (error.status === 401) return "Your session has expired. Sign in again to continue.";
  return error.message;
}

/** The fields that differ from the saved account; empty when nothing changed. */
export function changedFields(member: StaffMember, values: EditStaffValues): UpdateStaffInput {
  const changes: UpdateStaffInput = {};
  const first = values.first_name.trim();
  const last = values.last_name.trim();
  const username = values.username.trim();
  if (first !== member.firstName) changes.first_name = first;
  if (last !== member.lastName) changes.last_name = last;
  if (username !== member.username) changes.username = username;
  if (values.password !== "") changes.password = values.password;
  return changes;
}

export function useEditStaff(member: StaffMember, onSaved: (user: User) => void) {
  const { withPin } = usePin();
  const queryClient = useQueryClient();
  const [serverError, setServerError] = useState<string | null>(null);

  const form = useForm({
    defaultValues: {
      first_name: member.firstName,
      last_name: member.lastName,
      username: member.username,
      password: "",
    } satisfies EditStaffValues,
    validators: { onChange: editStaffSchema },
    onSubmit: async ({ value }) => {
      setServerError(null);
      const changes = changedFields(member, value);
      if (Object.keys(changes).length === 0) return;

      try {
        const user = await withPin((pin) => updateUser(member.id, changes, pin), {
          title: "Save changes",
          description: `Enter your PIN to save changes to ${member.name}'s account.`,
        });
        if (!user) return; // PIN prompt cancelled: keep the edits on screen.

        await queryClient.invalidateQueries({ queryKey: ["users"] });
        onSaved(user);
      } catch (error) {
        setServerError(editErrorMessage(error, changes.username));
      }
    },
  });

  return { form, serverError };
}
