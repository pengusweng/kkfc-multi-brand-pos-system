import { cn } from "cn";

type NavSectionLabelProps = {
  children: string;
  id: string;
  collapsed: boolean;
};

export default function NavSectionLabel({ children, id, collapsed }: NavSectionLabelProps) {
  return (
    <>
      <p
        id={id}
        className={cn(
          "px-2.5 pt-5 pb-2 text-xs font-semibold tracking-[0.12em] text-[#c7d9ed] uppercase",
          collapsed && "lg:hidden",
        )}
      >
        {children}
      </p>
      {collapsed ? <hr aria-hidden="true" className="mx-1 my-4 hidden border-[#30445a] lg:block" /> : null}
    </>
  );
}
