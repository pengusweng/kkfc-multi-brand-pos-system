export type PageItem = number | "gap-start" | "gap-end";

// Always shows the first and last page plus the current page's neighbours,
// e.g. 1 … 4 5 6 … 10. Near either end it shows the first/last five instead,
// and a gap that would hide a single page shows that page.
export function pageItems(page: number, totalPages: number): PageItem[] {
  if (totalPages <= 7) return Array.from({ length: totalPages }, (_, i) => i + 1);

  const shown = new Set([1, totalPages, page - 1, page, page + 1]);
  if (page <= 4) [2, 3, 4, 5].forEach((p) => shown.add(p));
  if (page >= totalPages - 3) [1, 2, 3, 4].forEach((n) => shown.add(totalPages - n));

  const pages = [...shown].filter((p) => p >= 1 && p <= totalPages).sort((a, b) => a - b);
  const items: PageItem[] = [];
  pages.forEach((p, i) => {
    const prev = pages[i - 1];
    if (prev !== undefined && p - prev === 2) items.push(p - 1);
    else if (prev !== undefined && p - prev > 2) items.push(i === 1 ? "gap-start" : "gap-end");
    items.push(p);
  });
  return items;
}
