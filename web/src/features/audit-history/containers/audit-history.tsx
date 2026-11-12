"use client";

import { useState } from "react";
import Pagination from "@/src/components/ui/molecules/pagination";
import PageTitle from "@/src/features/dashboard/components/atoms/page-title";
import AuditTable from "../components/organisms/audit-table";
import { AUDIT_PAGE_SIZE, MOCK_AUDIT_ENTRIES } from "../utils/audit";

export default function AuditHistoryPage() {
  const [page, setPage] = useState(1);

  // Paged client-side over placeholder data until the audit endpoint is wired up.
  const total = MOCK_AUDIT_ENTRIES.length;
  const totalPages = Math.max(1, Math.ceil(total / AUDIT_PAGE_SIZE));
  const entries = MOCK_AUDIT_ENTRIES.slice((page - 1) * AUDIT_PAGE_SIZE, page * AUDIT_PAGE_SIZE);

  return (
    <section className="motion-safe:animate-page-in">
      <PageTitle>Audit history</PageTitle>

      <AuditTable
        entries={entries}
        footer={
          total > 0 ? (
            <Pagination
              page={page}
              pageSize={AUDIT_PAGE_SIZE}
              total={total}
              totalPages={totalPages}
              onPageChange={setPage}
            />
          ) : null
        }
      />
    </section>
  );
}
