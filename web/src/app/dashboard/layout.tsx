import { Suspense } from "react";
import PageBackground from "@/src/components/layout/page-background";
import SessionNavbar from "@/src/features/dashboard/components/organisms/session-navbar";
import NavbarSkeleton from "@/src/features/dashboard/components/organisms/navbar-skeleton";

export const instant = false;

// Shared by every /dashboard page. Layouts stay mounted across navigations, so the
// navbar (and its collapsed state) persists and only the content area changes.
// The session read sits in its own boundary so it never holds up the page content.
export default function DashboardLayout({ children }: LayoutProps<"/dashboard">) {
  return (
    <div className="flex min-h-dvh flex-1 flex-col lg:flex-row">
      <Suspense fallback={<NavbarSkeleton />}>
        <SessionNavbar />
      </Suspense>
      <PageBackground className="flex-col items-stretch justify-start p-4 sm:p-8 lg:items-stretch">
        {children}
      </PageBackground>
    </div>
  );
}
