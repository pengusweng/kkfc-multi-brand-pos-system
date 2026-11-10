import { Suspense } from "react";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import UnauthorizedPage from "@/src/features/auth/containers/unauthorized";
import { validateCookie } from "@/src/features/auth/services/auth.service";
import { WEB_ROLES } from "@/src/features/auth/utils/webRoles";
import type { Metadata } from "next";

export const instant = false;

export const metadata: Metadata = {
  title: "Access restricted | KKFC Management",
};

// The page renders immediately; the session check streams in behind it and
// redirects anyone who shouldn't be here.
export default function Unauthorized() {
  return (
    <>
      <UnauthorizedPage />
      <Suspense fallback={null}>
        <CheckAccess />
      </Suspense>
    </>
  );
}

async function CheckAccess() {
  const token = (await cookies()).get("kkfc_session")?.value;
  if (!token) redirect("/login");

  const user = await validateCookie(token);
  if (!user) redirect("/login");
  if (WEB_ROLES.has(user.role)) redirect("/dashboard");

  return null;
}
