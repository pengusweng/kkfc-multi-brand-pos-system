"use client";

import type { UserRole } from "../../schemas/userSchema";
import type { StaffStatusFilter } from "../../utils/staff";
import RoleSelect from "../molecules/role-select";
import StaffSearchField from "../molecules/staff-search-field";
import StatusFilter from "../molecules/status-filter";

type StaffFilterBarProps = {
  query: string;
  onQueryChange: (query: string) => void;
  status: StaffStatusFilter;
  onStatusChange: (status: StaffStatusFilter) => void;
  role: UserRole | undefined;
  onRoleChange: (role: UserRole | undefined) => void;
  counts: Record<StaffStatusFilter, number>;
  resultCount: number;
};

export default function StaffFilterBar({
  query,
  onQueryChange,
  status,
  onStatusChange,
  role,
  onRoleChange,
  counts,
  resultCount,
}: StaffFilterBarProps) {
  return (
    <div className="mt-6 flex flex-col gap-3 rounded-xl border border-hairline bg-card p-3 md:flex-row md:flex-wrap md:items-center md:gap-x-4 md:gap-y-3 md:px-4">
      <StaffSearchField value={query} onChange={onQueryChange} />
      <RoleSelect value={role} onChange={onRoleChange} />
      <StatusFilter value={status} onChange={onStatusChange} counts={counts} />
      <p aria-live="polite" className="text-sm text-ink-muted tabular-nums md:ml-auto">
        {resultCount} {resultCount === 1 ? "account" : "accounts"}
      </p>
    </div>
  );
}
