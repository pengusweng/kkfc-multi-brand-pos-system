"use client";

import { useState } from "react";
import { UserPlus } from "lucide-react";
import { Button } from "@/components/ui/button";
import PageTitle from "@/src/features/dashboard/components/atoms/page-title";
import CreateStaffModal from "../components/organisms/create-staff-modal";
import EditStaffModal from "../components/organisms/edit-staff-modal";
import StaffDetailModal from "../components/organisms/staff-detail-modal";
import StaffFilterBar from "../components/organisms/staff-filter-bar";
import StaffPagination from "../components/molecules/staff-pagination";
import StaffTable from "../components/organisms/staff-table";
import { useDeactivateStaff } from "../hooks/useDeactivateStaff";
import { useDebouncedValue } from "../hooks/useDebouncedValue";
import { USERS_PAGE_SIZE, useUsers } from "../hooks/useUsers";
import type { UserRole } from "../schemas/userSchema";
import { nextSort, toStaffMember, type StaffMember, type StaffSort, type StaffStatusFilter } from "../utils/staff";

const NO_COUNTS: Record<StaffStatusFilter, number> = { all: 0, active: 0, inactive: 0 };

export default function StaffAccounts() {
  const [query, setQuery] = useState("");
  const [status, setStatus] = useState<StaffStatusFilter>("all");
  const [role, setRole] = useState<UserRole | undefined>();
  const [sort, setSort] = useState<StaffSort>(null);
  const search = useDebouncedValue(query.trim());
  const [creating, setCreating] = useState(false);

  const [viewing, setViewing] = useState<StaffMember | null>(null);
  const [modalOpen, setModalOpen] = useState(false);

  const [editOpen, setEditOpen] = useState(false);

  const { deactivate, error: deactivateError, resetError } = useDeactivateStaff((member) => {
    setViewing(member); // the modal now shows "Inactive" and hides the Deactivate button
  });

  const filterKey = `${status}|${role ?? ""}|${search}|${sort ? `${sort.by}:${sort.order}` : ""}`;
  const [paging, setPaging] = useState({ filterKey, page: 1 });
  if (paging.filterKey !== filterKey) setPaging({ filterKey, page: 1 });
  const page = paging.filterKey === filterKey ? paging.page : 1;

  const { data, error, isPending, isPlaceholderData } = useUsers({ status, search, role, sort, page });

  const staff = data?.data.map(toStaffMember) ?? [];
  const meta = data?.meta;
  const total = meta?.total ?? 0;

  let emptyMessage = "No accounts match these filters.";
  if (error) emptyMessage = error.message;
  else if (meta?.counts.all === 0 && !search && !role) emptyMessage = "No staff accounts yet.";

  return (
    <section className="motion-safe:animate-page-in">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <PageTitle>Staff accounts</PageTitle>
        <Button size="lg" className="h-10 px-4 font-semibold" onClick={() => setCreating(true)}>
          <UserPlus aria-hidden="true" />
          Add staff
        </Button>
      </div>

      <StaffFilterBar
        query={query}
        onQueryChange={setQuery}
        status={status}
        onStatusChange={setStatus}
        role={role}
        onRoleChange={setRole}
        counts={meta?.counts ?? NO_COUNTS}
        resultCount={total}
      />

      <StaffTable
        staff={staff}
        sort={sort}
        onSort={(by) => setSort((current) => nextSort(current, by))}
        onView={(member) => {
          setViewing(member);
          setModalOpen(true);
        }}
        loading={isPending || isPlaceholderData}
        skeletonRows={staff.length || USERS_PAGE_SIZE}
        emptyMessage={emptyMessage}
        footer={
          total > 0 ? (
            <StaffPagination
              page={page}
              pageSize={USERS_PAGE_SIZE}
              total={total}
              totalPages={meta?.totalPages ?? 1}
              onPageChange={(next) => setPaging({ filterKey, page: next })}
            />
          ) : null
        }
      />

      <StaffDetailModal
        member={viewing}
        open={modalOpen}
        onOpenChange={(open) => {
          setModalOpen(open);
          if (!open) resetError();
        }}
        onDeactivate={(member) => deactivate(member)}
        onEdit={() => {
          resetError();
          setModalOpen(false);
          setEditOpen(true);
        }}
        error={deactivateError}
      />

      <EditStaffModal
        member={viewing}
        open={editOpen}
        onOpenChange={(open) => {
          setEditOpen(open);
          if (!open) setModalOpen(true); // cancel goes back to the profile
        }}
        onSaved={(user) => {
          setViewing(toStaffMember(user));
          setEditOpen(false);
          setModalOpen(true);
        }}
      />

      <CreateStaffModal
        open={creating}
        onOpenChange={setCreating}
        onCreated={(user) => {
          // Confirm by opening the new account's profile.
          setCreating(false);
          setViewing(toStaffMember(user));
          setModalOpen(true);
        }}
      />
    </section>
  );
}
