import { z } from "zod";
import { ApiError } from "@/src/lib/api-error";
import { loginSchema, type LoginUser } from "../schemas/loginSchema";
import { loginSessionSchema, type LoginSession } from "../schemas/loginSessionSchema";

const apiErrorSchema = z.object({
  message: z.union([z.string().min(1), z.array(z.string().min(1)).min(1)]),
});

const pinErrorSchema = z.object({
  code: z.enum(["PIN_REQUIRED", "INVALID_PIN", "PIN_LOCKED", "PIN_NOT_CONFIGURED"]),
  message: z.string(),
  locked_until: z.iso.datetime().optional(),
});

/**
 * Signs in. Superadmins also need `pin`: without it the server answers with an
 * ApiError coded PIN_REQUIRED, and a wrong one with INVALID_PIN, PIN_LOCKED
 * (retryAfter in seconds) or PIN_NOT_CONFIGURED.
 */
export async function login(input: LoginUser, pin?: string): Promise<LoginSession> {
  const credentials = loginSchema.parse(input);
  let response: Response;

  try {
    response = await fetch("/api/auth/login", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        ...(pin ? { "X-Action-Pin": pin } : {}),
      },
      body: JSON.stringify(credentials),
      cache: "no-store",
      signal: AbortSignal.timeout(10_000),
    });
  } catch {
    throw ApiError.network();
  }

  const body: unknown = await response.json().catch(() => null);

  if (!response.ok) {
    const pinError = pinErrorSchema.safeParse(body);
    if (pinError.success) {
      const { code, message, locked_until } = pinError.data;
      const retryAfter = locked_until
        ? Math.max(1, Math.ceil((Date.parse(locked_until) - Date.now()) / 1000))
        : undefined;
      throw new ApiError(response.status, code, message, retryAfter);
    }

    if (response.status === 401) throw new ApiError(401, "INVALID_CREDENTIALS", "Invalid username or password.");

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

export async function logout(): Promise<void> {
  let response: Response;

  try {
    response = await fetch("/api/auth/logout", { method: "POST", cache: "no-store" });
  } catch {
    throw new Error("Unable to reach the server. Please try again.");
  }

  if (!response.ok) throw new Error("Unable to sign out. Please try again.");
}
