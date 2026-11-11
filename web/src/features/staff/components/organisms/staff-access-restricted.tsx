import { LockKeyhole } from "lucide-react";
import PageTitle from "@/src/features/dashboard/components/atoms/page-title";

// Shown in place of Staff Accounts to signed-in roles that may not manage accounts.
export default function StaffAccessRestricted() {
  return (
    <section className="motion-safe:animate-page-in">
      <PageTitle>Staff accounts</PageTitle>
      <div className="mt-6 flex max-w-xl items-start gap-4 rounded-xl border border-hairline bg-card px-5 py-5">
        <LockKeyhole aria-hidden="true" strokeWidth={1.75} className="mt-0.5 size-6 shrink-0 text-primary-ink" />
        <div className="flex flex-col gap-1.5">
          <h2 className="text-base font-semibold text-ink">Only superadmins can manage staff accounts</h2>
          <p className="text-sm leading-relaxed text-ink-muted">
            Ask a superadmin if an account needs to be created, edited, or deactivated.
          </p>
        </div>
      </div>
    </section>
  );
}
