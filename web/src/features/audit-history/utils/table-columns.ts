// Column classes shared by the audit table header, rows and skeleton rows.
export const CLUSTER = "md:w-px md:pr-10 xl:pr-4";

export const COL = {
  time: "xl:w-[22%]",
  actor: "xl:w-[22%]",
  action: "xl:w-[30%]",
  outcome: "xl:w-[16%]",
  view: "xl:w-[10%]",
};

export const COLUMN_COUNT = Object.keys(COL).length;
