import { Suspense } from "react";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import DashboardPage from "@/src/features/dashboard/containers/dashboard";
import PageBackground from "@/src/components/layout/page-background";
import { validateCookie } from "@/src/features/auth/services/auth.service";
import { WEB_ROLES } from "@/src/features/auth/utils/webRoles";

export const instant = false;

export default function Dashboard() {
  return (
    <Suspense
      fallback={
        <PageBackground>
          <p role="status">Checking your session…</p>
        </PageBackground>
      }
    >
      <CheckAccess />
    </Suspense>
  );
}

async function CheckAccess() {
  const token = (await cookies()).get("kkfc_session")?.value;
  if (!token) redirect("/login");

  const user = await validateCookie(token);
  if (!user) redirect("/login");
  if (!WEB_ROLES.has(user.role)) redirect("/unauthorized");

  return <DashboardPage user={user} />;
}
