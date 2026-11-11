import { ApiError } from "@/src/lib/api-error";
import type { CreateStaffInput } from "../schemas/createStaffSchema";
import type { UpdateStaffInput } from "../schemas/editStaffSchema";
import { userSchema, usersPageSchema, type User, type UserRole, type UsersPage } from "../schemas/userSchema";
import type { StaffSort, StaffStatusFilter } from "../utils/staff";

export type GetUsersParams = {
  page: number;
  limit: number;
  status: StaffStatusFilter;
  search?: string;
  role?: UserRole;
  sort?: StaffSort;
};

export async function getUsers({ page, limit, status, search, role, sort }: GetUsersParams): Promise<UsersPage> {
  const params = new URLSearchParams({ page: String(page), limit: String(limit), status });
  if (search) params.set("search", search);
  if (role) params.set("role", role);
  if (sort) {
    params.set("sortBy", sort.by);
    params.set("sortOrder", sort.order);
  }

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

export async function createUser(input: CreateStaffInput, pin: string): Promise<User> {
  let response: Response;
  try {
    response = await fetch("/api/users", {
      method: "POST",
      headers: { "Content-Type": "application/json", Accept: "application/json", "X-Action-Pin": pin },
      body: JSON.stringify(input),
      cache: "no-store",
      signal: AbortSignal.timeout(10_000),
    });
  } catch {
    throw ApiError.network();
  }

  if (!response.ok) throw await ApiError.fromResponse(response, "Unable to create the account. Please try again.");

  const result = userSchema.safeParse(await response.json().catch(() => null));
  if (!result.success) throw new ApiError(response.status, undefined, "The server returned an invalid account.");
  return result.data;
}

export async function deactivateUser(userId: string, pin: string): Promise<User> {
  let response: Response;
  try {
    response = await fetch(`/api/users/${encodeURIComponent(userId)}`, {
      method: "DELETE",
      headers: { Accept: "application/json", "X-Action-Pin": pin},
      cache: "no-store",
      signal: AbortSignal.timeout(10_000),
    });
  } catch {
    throw ApiError.network();
  }

  if (!response.ok) throw await ApiError.fromResponse(response, "Unable to deactivate the account. Please try again.");

  const result = userSchema.safeParse(await response.json().catch(() => null));
  if (!result.success) throw new ApiError(response.status, undefined, "The server returned an invalid account.");
  return result.data;
}

// PATCH /api/users/:id is PIN-protected. Send only the fields that changed.
export async function updateUser(userId: string, input: UpdateStaffInput, pin: string): Promise<User> {
  let response: Response;
  try {
    response = await fetch(`/api/users/${encodeURIComponent(userId)}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json", Accept: "application/json", "X-Action-Pin": pin },
      body: JSON.stringify(input),
      cache: "no-store",
      signal: AbortSignal.timeout(10_000),
    });
  } catch {
    throw ApiError.network();
  }

  if (!response.ok) throw await ApiError.fromResponse(response, "Unable to save the changes. Please try again.");

  const result = userSchema.safeParse(await response.json().catch(() => null));
  if (!result.success) throw new ApiError(response.status, undefined, "The server returned an invalid account.");
  return result.data;
}
