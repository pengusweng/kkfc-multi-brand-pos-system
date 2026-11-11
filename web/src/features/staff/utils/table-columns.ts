// Column classes shared by the staff table header, rows and skeleton rows.
export const HEAD = "h-11 px-3 md:px-4 text-[0.8125rem] font-semibold tracking-[0.02em] text-ink-muted";

export const CLUSTER = "md:w-px md:pr-10 xl:pr-4";

export const COL = {
  name: "xl:w-[28%]",
  username: "xl:w-[22%]",
  role: "xl:w-[24%]",
  status: "xl:w-[16%]",
  view: "xl:w-[10%]",
};

export const COLUMN_COUNT = Object.keys(COL).length;
