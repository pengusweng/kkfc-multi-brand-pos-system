import { useMutation, useQueryClient } from "@tanstack/react-query";
import { usePin } from "../../pin/hooks/usePin";
import { StaffMember } from "../utils/staff";
import { deactivateUser } from "../services/users.service";
import { ApiError } from "@/src/lib/api-error";

function deactivateErrorMessage(error: unknown): string {
  if (!(error instanceof ApiError)) return "Unable to deactivate the account. Please try again.";
  if (error.code === "USER_NOT_FOUND") return "This account is already inactive or no longer exists.";
  if (error.code === "CANNOT_MODIFY_PRIVILEGED_ACCOUNT") return "Only a superadmin can deactivate this account.";
  if (error.status === 401) return "Your session has expired. Sign in again to continue.";
  return error.message;
}

export function useDeactivateStaff(onDeactivated: (member: StaffMember) => void) {
  const { withPin } = usePin();
  const queryClient = useQueryClient();

  const mutation = useMutation({
    mutationFn: (member: StaffMember) =>
      withPin((pin) => deactivateUser(member.id, pin), {
        title: "Deactivate account",
        description: `Enter your PIN to deactivate ${member.name}. They won't be able to sign in.`,
      }),
    onSuccess: async (user, member) => {
      if (!user) return; // PIN prompt cancelled
      await queryClient.invalidateQueries({ queryKey: ["users"] }); // refreshes the table and the counts
      onDeactivated({ ...member, status: "inactive" });
    },
  });

    return {
    deactivate: mutation.mutate,
    pending: mutation.isPending,
    error: mutation.error ? deactivateErrorMessage(mutation.error) : null,
    resetError: mutation.reset,
  };

}