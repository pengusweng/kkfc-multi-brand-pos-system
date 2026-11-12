import { RotateCw } from "lucide-react";
import { cn } from "cn";
import { Button } from "@/components/ui/button";

export default function RetryButton({
  pending,
  onRetry,
  className,
}: {
  pending: boolean;
  onRetry: () => void;
  className?: string;
}) {
  return (
    <Button
      onClick={onRetry}
      disabled={pending}
      aria-busy={pending}
      className={cn(
        "h-12 w-full gap-2 text-base font-semibold focus-visible:border-primary focus-visible:ring-primary/25 disabled:opacity-80",
        className,
      )}
    >
      <RotateCw
        aria-hidden="true"
        className={cn("size-4", pending && "motion-safe:animate-spin")}
      />
      {pending ? "Trying again…" : "Try again"}
    </Button>
  );
}
