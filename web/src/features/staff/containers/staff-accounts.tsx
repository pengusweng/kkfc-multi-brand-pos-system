import PageTitle from "@/src/features/dashboard/components/atoms/page-title";
import StaffTable from "../components/staff-table";

export default function StaffAccounts() {
  return (
    <section className="motion-safe:animate-page-in">
      <PageTitle>Staff accounts</PageTitle>

      <StaffTable />
    </section>
  );
}
