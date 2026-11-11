import { z } from "zod";
import type { UserRole } from "./userSchema";

// Roles a manager can hand out from the staff page. Superadmin and Manager
// accounts are deliberately not creatable here.
export const CREATABLE_ROLES = [
  "RECIPE_MANAGER",
  "SUPERVISOR",
  "KITCHEN_HEAD",
  "INVENTORY_STAFF",
  "KITCHEN_STAFF",
  "CASHIER_STAFF",
] as const satisfies readonly UserRole[];

export type CreatableRole = (typeof CREATABLE_ROLES)[number];

const isCreatableRole = (value: string): value is CreatableRole =>
  (CREATABLE_ROLES as readonly string[]).includes(value);

// Mirrors the backend's CreateUserDTO limits so most mistakes are caught before the PIN prompt.
export const createStaffSchema = z.object({
  first_name: z.string().trim().min(1, "Enter a first name.").max(100, "First name can be at most 100 characters."),
  last_name: z.string().trim().min(1, "Enter a last name.").max(100, "Last name can be at most 100 characters."),
  username: z.string().trim().min(1, "Enter a username.").max(16, "Username can be at most 16 characters."),
  role: z.string().refine(isCreatableRole, "Choose a role."),
  password: z.string().min(8, "Password must be at least 8 characters.").max(32, "Password can be at most 32 characters."),
});

export type CreateStaffValues = z.input<typeof createStaffSchema>;

export type CreateStaffInput = Omit<z.output<typeof createStaffSchema>, "role"> & { role: CreatableRole };
