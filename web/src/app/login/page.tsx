import { Suspense } from "react";
import LoginPage from "@/src/features/auth/containers/login";
import PageBackground from "@/src/components/layout/page-background";
import { validateCookie } from "@/src/features/auth/services/auth.service";
import { WEB_ROLES } from "@/src/features/auth/utils/webRoles";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";

export const instant = false;

type LoginProps = {
  searchParams: Promise<{ switchAccount?: string | string[] }>;
};

export default function Login({ searchParams }: LoginProps) {
  return (
    <Suspense
      fallback={
        <PageBackground>
          <p role="status">Checking your session…</p>
        </PageBackground>
      }
    >
      <CheckSession searchParams={searchParams} />
    </Suspense>
  );
}

async function CheckSession({ searchParams }: LoginProps) {
  if ((await searchParams).switchAccount === "1") return <LoginPage />;

  const token = (await cookies()).get("kkfc_session")?.value;
  if (!token) return <LoginPage />;

  const user = await validateCookie(token);
  if (!user) return <LoginPage />;

  redirect(WEB_ROLES.has(user.role) ? "/dashboard" : "/unauthorized");
}
