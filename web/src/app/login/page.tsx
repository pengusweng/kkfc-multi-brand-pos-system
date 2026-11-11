import { Suspense } from "react";
import LoginPage from "@/src/features/auth/containers/login";
import { validateCookie } from "@/src/features/auth/services/auth.service";
import { WEB_ROLES } from "@/src/features/auth/utils/webRoles";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";

export const instant = false;

type LoginProps = {
  searchParams: Promise<{ switchAccount?: string | string[] }>;
};

// The form renders immediately; the session check streams in behind it and only
// redirects when someone is already signed in.
export default function Login({ searchParams }: LoginProps) {
  return (
    <>
      <LoginPage />
      <Suspense fallback={null}>
        <RedirectSignedIn searchParams={searchParams} />
      </Suspense>
    </>
  );
}

async function RedirectSignedIn({ searchParams }: LoginProps) {
  if ((await searchParams).switchAccount === "1") return null;

  const token = (await cookies()).get("kkfc_session")?.value;
  if (!token) return null;

  const user = await validateCookie(token);
  if (!user) return null;

  redirect(WEB_ROLES.has(user.role) ? "/dashboard" : "/unauthorized");
}
