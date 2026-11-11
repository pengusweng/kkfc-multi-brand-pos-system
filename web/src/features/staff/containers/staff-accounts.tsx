"use client";

import { useState } from "react";
import PageTitle from "@/src/features/dashboard/components/atoms/page-title";
import StaffDetailModal from "../components/organisms/staff-detail-modal";
import StaffFilterBar from "../components/organisms/staff-filter-bar";
import StaffPagination from "../components/molecules/staff-pagination";
import StaffTable from "../components/organisms/staff-table";
import { useDebouncedValue } from "../hooks/useDebouncedValue";
import { USERS_PAGE_SIZE, useUsers } from "../hooks/useUsers";
import type { UserRole } from "../schemas/userSchema";
import { toStaffMember, type StaffMember, type StaffStatusFilter } from "../utils/staff";

const NO_COUNTS: Record<StaffStatusFilter, number> = { all: 0, active: 0, inactive: 0 };

export default function StaffAccounts() {
  const [query, setQuery] = useState("");
  const [status, setStatus] = useState<StaffStatusFilter>("all");
  const [role, setRole] = useState<UserRole | undefined>();
  const search = useDebouncedValue(query.trim());

  // Kept after closing so the modal's content doesn't vanish mid exit animation.
  const [viewing, setViewing] = useState<StaffMember | null>(null);
  const [modalOpen, setModalOpen] = useState(false);

  // The page belongs to one status + role + search combination; changing any
  // of them (including when the debounced search settles) goes back to page 1.
  const filterKey = `${status}|${role ?? ""}|${search}`;
  const [paging, setPaging] = useState({ filterKey, page: 1 });
  const page = paging.filterKey === filterKey ? paging.page : 1;

  const { data, error, isPending, isPlaceholderData } = useUsers({ status, search, role, page });

  const staff = data?.data.map(toStaffMember) ?? [];
  const meta = data?.meta;
  const total = meta?.total ?? 0;

  let emptyMessage = "No accounts match these filters.";
  if (error) emptyMessage = error.message;
  else if (meta?.counts.all === 0 && !search && !role) emptyMessage = "No staff accounts yet.";

  return (
    <section className="motion-safe:animate-page-in">
      <PageTitle>Staff accounts</PageTitle>

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

      <StaffDetailModal member={viewing} open={modalOpen} onOpenChange={setModalOpen} />
    </section>
  );
}
