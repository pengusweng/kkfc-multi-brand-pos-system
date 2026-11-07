import * as React from "react"
import { Input as ShadcnInput } from "@/components/ui/input"
import { cn } from "cn"

function Input({ className, ...props }: React.ComponentProps<typeof ShadcnInput>) {
  return (
    <ShadcnInput
      className={cn(
        "h-12 px-3 md:text-base focus-visible:border-primary focus-visible:ring-2 focus-visible:ring-primary/15",
        className
      )}
      {...props}
    />
  )
}

export { Input }
