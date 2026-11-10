import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Ban, Check, ChevronRight } from "lucide-react";

type StaffStatus = "active" | "inactive";

type StaffMember = {
  name: string;
  username: string;
  role: string;
  department: string;
  status: StaffStatus;
};

// Placeholder rows until the staff API is wired in.
const STAFF: StaffMember[] = [
  { name: "Ana Lopez (Shift Supervisor)", username: "supervisor.web", role: "Supervisor", department: "Floor Operations", status: "active" },
  { name: "Ana Reyes", username: "cashier.pending1", role: "Cashier Staff", department: "Front Counter", status: "active" },
  { name: "Arnel Ramos (Dispatcher)", username: "cook.dispatch", role: "Kitchen Staff", department: "Dispatch & Packing", status: "active" },
  { name: "Ben Santos", username: "cashier.expired1", role: "Cashier Staff", department: "Front Counter", status: "inactive" },
  { name: "Carlo Reyes (Floor Lead)", username: "staff.multi", role: "Supervisor", department: "Floor Operations", status: "active" },
  { name: "Carlos Cruz", username: "staff.inactive1", role: "Inventory Staff", department: "Stockroom & Inventory", status: "inactive" },
  { name: "Chef Leo (Line Cook)", username: "cook.prep", role: "Kitchen Staff", department: "Culinary / Kitchen", status: "active" },
  { name: "Chef Marco (Recipe Manager · GC)", username: "recipe.manager", role: "Recipe Manager", department: "Culinary Innovation", status: "active" },
  { name: "Chef Teresa", username: "supervisor.ai1", role: "Supervisor", department: "Culinary / Kitchen", status: "active" },
  { name: "Chef Teresa (Kitchen Head)", username: "cook.qc", role: "Kitchen Head", department: "Commercial Kitchen", status: "active" },
  { name: "Clara Diaz", username: "cashier.cancelled1", role: "Cashier Staff", department: "Front Counter", status: "inactive" },
];

// Soft status badges (DESIGN.md › Status Badges): tinted fill, 1px matching
// border, dark ink text, always paired with an icon so color is never the only cue.
const STATUS_BADGE: Record<StaffStatus, { label: string; icon: typeof Check; className: string }> = {
  active: {
    label: "Active",
    icon: Check,
    className:
      "border-[#9ed2b0] bg-[#e3f4e9] text-[#166b3a] dark:border-[oklch(0.62_0.13_150/0.4)] dark:bg-[oklch(0.62_0.13_150/0.14)] dark:text-[oklch(0.84_0.11_150)]",
  },
  inactive: {
    label: "Inactive",
    icon: Ban,
    className: "border-hairline bg-muted text-ink-muted",
  },
};

function StatusBadge({ status }: { status: StaffStatus }) {
  const { label, icon: Icon, className } = STATUS_BADGE[status];
  return (
    <span
      className={`inline-flex h-6 items-center gap-1.5 rounded-full border px-2.5 text-xs font-semibold tracking-[0.02em] whitespace-nowrap ${className}`}
    >
      <Icon aria-hidden="true" className="size-3.5" strokeWidth={2.5} />
      {label}
    </span>
  );
}

// Label/Meta style for headers, so the column names sit below the data in weight.
const HEAD = "h-11 px-3 md:px-4 text-[0.8125rem] font-semibold tracking-[0.02em] text-ink-muted";

// Column widths. Up to xl, Name and Username share the spare width while Role,
// Status and View hug their content and sit together on the right.
// From xl the table is wide enough that the browser's automatic layout hands
// almost all the spare width to the longest text (Name), leaving one huge gap.
// There the table switches to a fixed layout with set shares, so every gap
// between columns comes out roughly even across the full width.
const CLUSTER = "md:w-px md:pr-10 xl:pr-4";
const COL = {
  name: "xl:w-[28%]",
  username: "xl:w-[22%]",
  role: "xl:w-[24%]",
  status: "xl:w-[16%]",
  view: "xl:w-[10%]",
};

export default function StaffTable() {
  return (
    <div className="mt-6 overflow-hidden rounded-xl border border-hairline bg-card">
    <Table className="xl:table-fixed">
      <TableHeader>
        <TableRow className="border-hairline bg-surface-hover hover:bg-surface-hover">
          <TableHead className={`${HEAD} ${COL.name}`}>Name</TableHead>
          <TableHead className={`${HEAD} hidden md:table-cell ${COL.username}`}>Username</TableHead>
          <TableHead className={`${HEAD} ${CLUSTER} hidden md:table-cell ${COL.role}`}>Role</TableHead>
          <TableHead className={`${HEAD} w-px ${COL.status}`}>Status</TableHead>
          <TableHead className={`${HEAD} w-px ${COL.view}`}>
            <span className="sr-only">Actions</span>
          </TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {STAFF.length === 0 ? (
          <TableRow className="hover:bg-transparent">
            <TableCell colSpan={5} className="px-4 py-10 text-center text-ink-muted">
              No staff accounts yet.
            </TableCell>
          </TableRow>
        ) : (
          STAFF.map((member) => (
            <TableRow key={member.username} className="border-hairline hover:bg-surface-hover/50">
              <TableCell className={`px-3 py-3 whitespace-normal md:px-4 md:whitespace-nowrap xl:whitespace-normal`}>
                <div className="flex flex-col gap-0.5">
                  <span className="font-semibold text-ink">{member.name}</span>
                  {/* Narrow screens drop the Username and Role columns; both ride along here instead. */}
                  <span className="text-ink-muted md:hidden">{member.username}</span>
                  <span className="text-ink-muted md:hidden">{member.role}</span>
                </div>
              </TableCell>
              <TableCell className="hidden px-4 py-3 text-ink-muted md:table-cell xl:break-all xl:whitespace-normal">{member.username}</TableCell>
              <TableCell className={`hidden px-4 py-3 md:table-cell xl:whitespace-normal ${CLUSTER}`}>
                <div className="flex flex-col gap-0.5">
                  <span className="text-ink">{member.role}</span>
                  <span className="text-ink-muted">{member.department}</span>
                </div>
              </TableCell>
              <TableCell className="px-3 py-3 md:px-4">
                <StatusBadge status={member.status} />
              </TableCell>
              <TableCell className="py-3 pr-1.5 pl-1 text-right md:pr-2 md:pl-4">
                <button
                  type="button"
                  aria-label={`View ${member.name}`}
                  className="inline-flex h-8 cursor-pointer items-center gap-1 rounded-md pr-1.5 pl-2.5 font-semibold text-ink transition-colors outline-none hover:bg-ink/6 focus-visible:ring-2 focus-visible:ring-primary/40 active:bg-ink/10 [&_svg]:text-ink-muted"
                >
                  View
                  <ChevronRight aria-hidden="true" className="size-4" strokeWidth={2.25} />
                </button>
              </TableCell>
            </TableRow>
          ))
        )}
      </TableBody>
    </Table>
    </div>
  );
}
