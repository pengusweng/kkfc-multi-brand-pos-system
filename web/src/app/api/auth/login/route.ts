import { NextResponse } from "next/server";
import { loginSchema } from "@/src/features/auth/schemas/loginSchema";
import { loginSessionSchema } from "@/src/features/auth/schemas/loginSessionSchema";

const headers = { "Cache-Control": "no-store" };

export async function POST(request: Request) {
  const credentials = loginSchema.safeParse(await request.json().catch(() => null));
  if (!credentials.success) {
    return NextResponse.json(
      { message: credentials.error.issues.map((issue) => issue.message) },
      { status: 400, headers },
    );
  }

  const apiUrl = process.env.API_URL;
  if (!apiUrl) {
    return NextResponse.json({ message: "Login is unavailable." }, { status: 503, headers });
  }

  let upstream: Response;
  try {
    upstream = await fetch(new URL("/api/auth/login", apiUrl), {
      method: "POST",
      headers: { "Content-Type": "application/json", Accept: "application/json" },
      body: JSON.stringify(credentials.data),
      cache: "no-store",
      signal: AbortSignal.timeout(10_000),
    });
  } catch {
    return NextResponse.json({ message: "Unable to reach the server." }, { status: 502, headers });
  }

  const body: unknown = await upstream.json().catch(() => null);
  if (!upstream.ok) {
    const status = upstream.status === 400 || upstream.status === 401 ? upstream.status : 502;
    return NextResponse.json(
      status === 400 && body ? body : {
        message: status === 401 ? "Invalid username or password." : "Unable to sign in.",
      },
      { status, headers },
    );
  }

  const session = loginSessionSchema.safeParse(body);
  if (!session.success || Date.parse(session.data.expires_at) <= Date.now()) {
    return NextResponse.json(
      { message: "The server returned an invalid login response." },
      { status: 502, headers },
    );
  }

  const response = NextResponse.json(session.data, { headers });
  response.cookies.set("kkfc_session", session.data.token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    path: "/",
    expires: new Date(session.data.expires_at),
  });
  return response;
}
