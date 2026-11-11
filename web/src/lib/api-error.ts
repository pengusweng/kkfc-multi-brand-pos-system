import { z } from "zod";

const errorBodySchema = z.object({
  code: z.string().optional(),
  message: z.union([z.string(), z.array(z.string())]).optional(),
});

// A failed API response, keeping the backend's machine-readable `code`
// (e.g. INVALID_PIN, USERNAME_ALREADY_EXISTS) so callers can react to it.
export class ApiError extends Error {
  constructor(
    readonly status: number,
    readonly code: string | undefined,
    message: string,
    /** Seconds to wait before retrying, from the Retry-After header. */
    readonly retryAfter?: number,
  ) {
    super(message);
    this.name = "ApiError";
  }

  static async fromResponse(response: Response, fallback: string): Promise<ApiError> {
    const body = errorBodySchema.safeParse(await response.json().catch(() => null));
    const message = body.success ? body.data.message : undefined;
    const retryAfter = Number(response.headers.get("Retry-After")) || undefined;
    return new ApiError(
      response.status,
      body.success ? body.data.code : undefined,
      (Array.isArray(message) ? message.join(" ") : message) || fallback,
      retryAfter,
    );
  }

  static network(): ApiError {
    return new ApiError(0, "NETWORK", "Unable to reach the server. Please try again.");
  }
}
