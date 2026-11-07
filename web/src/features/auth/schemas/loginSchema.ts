import { z } from "zod";

export const loginSchema = z.object({
  username: z.string()
    .trim()
    .min(1, "Username is required.")
    .max(16, "Username should not exceed 16 characters."),

  password: z.string()
    .min(8, "Password must be at least 8 characters.")
    .max(32, "Password should not exceed 32 characters."),
});

export type LoginUser = z.infer<typeof loginSchema>;