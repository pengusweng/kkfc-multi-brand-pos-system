import { z } from "zod";

export const userRoleSchema = z.enum([
  "SUPERADMIN",
  "RECIPE_MANAGER",
  "SUPERVISOR",
  "KITCHEN_HEAD",
  "INVENTORY_STAFF",
  "KITCHEN_STAFF",
  "CASHIER_STAFF",
]);

export const userSchema = z.object({
  user_id: z.uuid(),
  username: z.string(),
  first_name: z.string(),
  last_name: z.string(),
  role: userRoleSchema,
  is_active: z.boolean(),
  created_at: z.iso.datetime(),
  modified_at: z.iso.datetime(),
});

const statusCountsSchema = z.object({
  all: z.number().int(),
  active: z.number().int(),
  inactive: z.number().int(),
});

// GET /api/users response.
export const usersPageSchema = z.object({
  data: z.array(userSchema),
  meta: z.object({
    page: z.number().int(),
    limit: z.number().int(),
    total: z.number().int(),
    totalPages: z.number().int(),
    counts: statusCountsSchema,
  }),
});

export type User = z.infer<typeof userSchema>;
export type UserRole = z.infer<typeof userRoleSchema>;
export type UsersPage = z.infer<typeof usersPageSchema>;
