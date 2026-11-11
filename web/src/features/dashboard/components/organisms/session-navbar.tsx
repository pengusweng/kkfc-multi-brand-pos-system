import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { validateCookie } from "@/src/features/auth/services/auth.service";
import { WEB_ROLES } from "@/src/features/auth/utils/webRoles";
import Navbar from "./navbar";


export default async function SessionNavbar() {
  const token = (await cookies()).get("kkfc_session")?.value;
  if (!token) redirect("/login");

  const user = await validateCookie(token);
  if (!user) redirect("/login");
  if (!WEB_ROLES.has(user.role)) redirect("/unauthorized");

  return (
    <Navbar
      user={{
        name: `${user.first_name} ${user.last_name}`.trim() || user.username,
        role: user.role,
        username: user.username,
      }}
    />
  );
}
