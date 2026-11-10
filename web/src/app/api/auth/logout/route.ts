import { cookies } from "next/headers";

// Revokes the backend session (best effort) and always clears the session cookie.
export async function POST() {
  const cookieStore = await cookies();
  const token = cookieStore.get("kkfc_session")?.value;
  const apiUrl = process.env.API_URL;

  if (token && apiUrl) {
    await fetch(new URL("/api/auth/logout", apiUrl), {
      method: "POST",
      headers: { Authorization: `Bearer ${token}` },
      cache: "no-store",
      signal: AbortSignal.timeout(10_000),
    }).catch(() => null);
  }

  cookieStore.delete("kkfc_session");
  return new Response(null, { status: 204, headers: { "Cache-Control": "no-store" } });
}
