import { usersPageSchema, type UserRole, type UsersPage } from "../schemas/userSchema";
import type { StaffStatusFilter } from "../utils/staff";

export type GetUsersParams = {
  page: number;
  limit: number;
  status: StaffStatusFilter;
  search?: string;
  role?: UserRole;
};

export async function getUsers({ page, limit, status, search, role }: GetUsersParams): Promise<UsersPage> {
  const params = new URLSearchParams({ page: String(page), limit: String(limit), status });
  if (search) params.set("search", search);
  if (role) params.set("role", role);

  let response: Response;
  try {
    response = await fetch(`/api/users?${params}`, {
      headers: { Accept: "application/json" },
      cache: "no-store",
      signal: AbortSignal.timeout(10_000),
    });
  } catch {
    throw new Error("Unable to reach the server. Please try again.");
  }

  if (response.status === 401) throw new Error("Your session has expired. Please sign in again.");
  if (response.status === 403) throw new Error("You don't have permission to view staff accounts.");
  if (!response.ok) throw new Error("Unable to load staff accounts. Please try again.");

  const body: unknown = await response.json().catch(() => null);
  const result = usersPageSchema.safeParse(body);
  if (!result.success) throw new Error("The server returned an invalid staff list.");

  return result.data;
}
