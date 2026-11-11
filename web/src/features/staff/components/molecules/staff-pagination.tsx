import { ChevronLeft, ChevronRight } from "lucide-react";
import { pageItems } from "../../utils/pagination";
import PageButton from "../atoms/page-button";

type StaffPaginationProps = {
  page: number;
  pageSize: number;
  total: number;
  totalPages: number;
  onPageChange: (page: number) => void;
};

export default function StaffPagination({ page, pageSize, total, totalPages, onPageChange }: StaffPaginationProps) {
  const first = total === 0 ? 0 : (page - 1) * pageSize + 1;
  const last = Math.min(page * pageSize, total);

  return (
    <div className="flex flex-wrap items-center justify-between gap-3 border-t border-hairline px-3 py-3 md:px-4">
      <p aria-live="polite" className="text-sm text-ink-muted tabular-nums">
        Showing {first}–{last} of {total}
      </p>

      {totalPages > 1 ? (
        <nav aria-label="Pagination" className="flex items-center gap-1">
          <PageButton
            variant="outlined"
            onClick={() => onPageChange(page - 1)}
            disabled={page <= 1}
            aria-label="Previous page"
          >
            <ChevronLeft aria-hidden="true" className="size-4" strokeWidth={2.25} />
          </PageButton>

          {/* Narrow screens get a compact "2 / 10" instead of the page list. */}
          <span className="px-2 text-sm text-ink-muted tabular-nums md:hidden">
            {page} / {totalPages}
          </span>

          <ol className="hidden items-center gap-1 md:flex">
            {pageItems(page, totalPages).map((item) =>
              typeof item === "number" ? (
                <li key={item}>
                  <PageButton
                    variant={item === page ? "current" : "plain"}
                    onClick={() => onPageChange(item)}
                    aria-label={`Page ${item}`}
                    aria-current={item === page ? "page" : undefined}
                  >
                    {item}
                  </PageButton>
                </li>
              ) : (
                <li key={item} aria-hidden="true" className="px-1 text-sm text-ink-muted">
                  …
                </li>
              ),
            )}
          </ol>

          <PageButton
            variant="outlined"
            onClick={() => onPageChange(page + 1)}
            disabled={page >= totalPages}
            aria-label="Next page"
          >
            <ChevronRight aria-hidden="true" className="size-4" strokeWidth={2.25} />
          </PageButton>
        </nav>
      ) : null}
    </div>
  );
}
