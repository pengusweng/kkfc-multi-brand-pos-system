import { z } from "zod";

// Mirrors the backend's UpdateUserDTO. Role can't be changed through the API,
// and a blank password means "keep the current one".
export const editStaffSchema = z.object({
  first_name: z.string().trim().min(1, "Enter a first name.").max(100, "First name can be at most 100 characters."),
  last_name: z.string().trim().min(1, "Enter a last name.").max(100, "Last name can be at most 100 characters."),
  username: z.string().trim().min(1, "Enter a username.").max(16, "Username can be at most 16 characters."),
  password: z
    .string()
    .refine((value) => value === "" || (value.length >= 8 && value.length <= 32), "Password must be 8 to 32 characters."),
});

export type EditStaffValues = z.input<typeof editStaffSchema>;

/** PATCH body: only the fields that changed. */
export type UpdateStaffInput = Partial<Omit<z.output<typeof editStaffSchema>, "password"> & { password: string }>;
