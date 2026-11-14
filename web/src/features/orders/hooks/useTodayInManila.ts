import { useSyncExternalStore } from "react";
import { todayInManila } from "@/src/features/audit-history/utils/audit";

const noSubscription = () => () => {};

/**
 * Today's Asia/Manila date as YYYY-MM-DD, read only in the browser. Reading the
 * clock during render would break prerendering, so the server snapshot is
 * undefined (no upper bound yet) and the real date arrives on hydration.
 */
export function useTodayInManila(): string | undefined {
  return useSyncExternalStore(noSubscription, todayInManila, () => undefined);
}
