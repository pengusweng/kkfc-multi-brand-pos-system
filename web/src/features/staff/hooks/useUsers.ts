import { keepPreviousData, useQuery } from "@tanstack/react-query";
import type { UserRole } from "../schemas/userSchema";
import { getUsers } from "../services/users.service";
import type { StaffSort, StaffStatusFilter } from "../utils/staff";

export const USERS_PAGE_SIZE = 15;

type UseUsersParams = { status: StaffStatusFilter; search: string; role?: UserRole; sort: StaffSort; page: number };

// One request per page. The previous page stays in `data` (isPlaceholderData)
// until the requested one arrives, so counts and totals don't blank out.
export function useUsers({ status, search, role, sort, page }: UseUsersParams) {
  return useQuery({
    queryKey: ["users", { status, search, role, sort, page, limit: USERS_PAGE_SIZE }],
    queryFn: () => getUsers({ page, limit: USERS_PAGE_SIZE, status, search, role, sort }),
    placeholderData: keepPreviousData,
    retry: false,
  });
}
