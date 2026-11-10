import * as React from "react"
import { Input as ShadcnInput } from "@/components/ui/input"
import { cn } from "cn"

function Input({ className, ...props }: React.ComponentProps<typeof ShadcnInput>) {
  return (
    <ShadcnInput
      className={cn(
        "h-12 bg-field px-3 text-ink caret-primary placeholder:text-ink-muted/80 autofill:shadow-[inset_0_0_0_100px_var(--field)] autofill:[-webkit-text-fill-color:var(--ink)] dark:bg-field md:text-base focus-visible:border-primary focus-visible:ring-2 focus-visible:ring-primary/15",
        className
      )}
      {...props}
    />
  )
}

export { Input }
