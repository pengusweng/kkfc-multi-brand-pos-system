import { z } from "zod";
import { loginSchema, type LoginUser } from "../schemas/loginSchema";
import { loginSessionSchema, type LoginSession } from "../schemas/loginSessionSchema";

const apiErrorSchema = z.object({
  message: z.union([z.string().min(1), z.array(z.string().min(1)).min(1)]),
});

export async function login(input: LoginUser): Promise<LoginSession> {
  const credentials = loginSchema.parse(input);
  let response: Response;

  try {
    response = await fetch("/api/auth/login", {
      method: "POST",
      headers: { "Content-Type": "application/json", Accept: "application/json" },
      body: JSON.stringify(credentials),
      cache: "no-store",
      signal: AbortSignal.timeout(10_000),
    });
  } catch {
    throw new Error("Unable to reach the server. Please try again.");
  }

  const body: unknown = await response.json().catch(() => null);

  if (!response.ok) {
    if (response.status === 401) throw new Error("Invalid username or password.");

    const error = apiErrorSchema.safeParse(body);
    if (response.status === 400 && error.success) {
      throw new Error(Array.isArray(error.data.message)
        ? error.data.message.join(" ")
        : error.data.message);
    }

    throw new Error("Unable to sign in. Please try again.");
  }

  const session = loginSessionSchema.safeParse(body);
  if (!session.success) throw new Error("The server returned an invalid login response.");

  return session.data;
}

export async function validateCookie(token: string): Promise<LoginSession["user"] | null> {
  if (!token) return null;

  const apiUrl = process.env.API_URL;
  if (!apiUrl) throw new Error("API_URL is missing.");

  const response = await fetch(new URL("/api/auth/me", apiUrl), {
    headers: { Authorization: `Bearer ${token}` },
    cache: "no-store",
    signal: AbortSignal.timeout(10_000),
  });

  if (response.status === 401) return null;
  if (!response.ok) throw new Error("Unable to check your session.");

  const body: unknown = await response.json().catch(() => null);
  const user = loginSessionSchema.shape.user.safeParse(body);
  if (!user.success) throw new Error("The server returned an invalid user response.");

  return user.data;
}
