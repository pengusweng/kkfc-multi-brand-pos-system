import { z } from "zod";

export const loginSessionSchema = z.object({
  token: z.string().min(1),
  expires_at: z.iso.datetime(),
  user: z.object({
    user_id: z.uuid(),
    username: z.string(),
    first_name: z.string(),
    last_name: z.string(),
    role: z.string().min(1),
    is_active: z.boolean(),
    created_at: z.iso.datetime(),
    modified_at: z.iso.datetime(),
  }),
});

export type LoginSession = z.infer<typeof loginSessionSchema>;
