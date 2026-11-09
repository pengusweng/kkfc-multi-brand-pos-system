import { cn } from "cn";

// Text inside the sidebar fades rather than disappearing: out quickly as the
// rail starts to narrow, back in once it has widened enough to hold it.
export function railFade(collapsed: boolean) {
  return cn(
    "transition-opacity duration-200 motion-reduce:transition-none",
    collapsed ? "lg:pointer-events-none lg:opacity-0 lg:duration-100" : "delay-100",
  );
}
