import { cn } from "cn";
import { Avatar } from "@/src/components/ui/atoms/avatar";
import { formatRole } from "../../utils/formatRole";

export type NavUserProps = {
  name: string;
  role: string;
  collapsed: boolean;
};

export default function NavUser({ name, role, collapsed }: NavUserProps) {
  return (
    <div
      title={collapsed ? `${name} · ${formatRole(role)}` : undefined}
      className={cn(
        "flex items-center gap-3 border-t border-[#30445a] px-3 py-4",
        collapsed && "lg:justify-center lg:px-0",
      )}
    >
      <Avatar name={name} />
      <div className={cn("min-w-0 leading-tight", collapsed && "lg:sr-only")}>
        <p className="truncate text-sm font-semibold">{name}</p>
        <p className="truncate text-xs text-[#c7d9ed]">{formatRole(role)}</p>
      </div>
    </div>
  );
}
