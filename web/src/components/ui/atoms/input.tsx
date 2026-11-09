import * as React from "react"
import { Input as ShadcnInput } from "@/components/ui/input"
import { cn } from "cn"

function Input({ className, ...props }: React.ComponentProps<typeof ShadcnInput>) {
  return (
    <ShadcnInput
      className={cn(
        "h-12 bg-white px-3 caret-primary autofill:shadow-[inset_0_0_0_100px_white] md:text-base focus-visible:border-primary focus-visible:ring-2 focus-visible:ring-primary/15",
        className
      )}
      {...props}
    />
  )
}

export { Input }
