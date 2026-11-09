import Navbar from "../components/navbar";
import PageBackground from "@/src/components/layout/page-background";
import type { LoginSession } from "@/src/features/auth/schemas/loginSessionSchema";

export default function DashboardPage({ user }: { user: LoginSession["user"] }) {
  return (
    <div className="flex min-h-dvh flex-1 flex-col lg:flex-row">
      <Navbar user={{ name: `${user.first_name} ${user.last_name}`.trim() || user.username, role: user.role, username: user.username }} />
      <PageBackground className="flex-col justify-start p-4 lg:items-stretch" />
    </div>
  );
}
