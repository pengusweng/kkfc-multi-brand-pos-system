import { Suspense, type ReactNode } from "react";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { validateCookie } from "@/src/features/auth/services/auth.service";
import { STAFF_ACCOUNT_ROLES } from "@/src/features/auth/utils/webRoles";
import StaffAccessRestricted from "@/src/features/staff/components/organisms/staff-access-restricted";
import StaffAccounts from "@/src/features/staff/containers/staff-accounts";

// The role check reads the session cookie, which Cache Components only allows
// behind a Suspense boundary; the dashboard chrome renders without waiting on it.
export default function Staff() {
  return (
    <Suspense fallback={null}>
      <RequireStaffAccess>
        <StaffAccounts />
      </RequireStaffAccess>
    </Suspense>
  );
}

async function RequireStaffAccess({ children }: { children: ReactNode }) {
  const token = (await cookies()).get("kkfc_session")?.value;
  if (!token) redirect("/login");

  const user = await validateCookie(token);
  if (!user) redirect("/login");
  if (!STAFF_ACCOUNT_ROLES.has(user.role)) return <StaffAccessRestricted />;

  return children;
}
