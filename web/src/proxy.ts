import { NextResponse, type NextRequest } from "next/server";

export function proxy(request: NextRequest) {
  const headers = new Headers(request.headers);

  // Cookie authentication needs an origin check for requests that change data.
  if (
    !["GET", "HEAD", "OPTIONS"].includes(request.method) &&
    !headers.has("authorization") &&
    headers.get("origin") !== request.nextUrl.origin
  ) {
    return NextResponse.json({ message: "Invalid request origin." }, { status: 403 });
  }

  const token = request.cookies.get("kkfc_session")?.value;
  if (token && !headers.has("authorization")) {
    headers.set("authorization", `Bearer ${token}`);
  }

  return NextResponse.next({ request: { headers } });
}

export const config = { matcher: "/api/:path*" };
