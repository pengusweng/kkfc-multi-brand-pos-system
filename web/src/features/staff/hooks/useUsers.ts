import { keepPreviousData, useQuery } from "@tanstack/react-query";
import type { UserRole } from "../schemas/userSchema";
import { getUsers } from "../services/users.service";
import type { StaffStatusFilter } from "../utils/staff";

export const USERS_PAGE_SIZE = 15;

type UseUsersParams = { status: StaffStatusFilter; search: string; role?: UserRole; page: number };

// One request per page. The previous page stays in `data` (isPlaceholderData)
// until the requested one arrives, so counts and totals don't blank out.
export function useUsers({ status, search, role, page }: UseUsersParams) {
  return useQuery({
    queryKey: ["users", { status, search, role, page, limit: USERS_PAGE_SIZE }],
    queryFn: () => getUsers({ page, limit: USERS_PAGE_SIZE, status, search, role }),
    placeholderData: keepPreviousData,
    retry: false,
  });
}
