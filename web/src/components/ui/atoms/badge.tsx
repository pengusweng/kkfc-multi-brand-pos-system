import * as React from "react"
import { cn } from "cn"

function Badge({ className, ...props }: React.ComponentProps<"span">) {
  return (
    <span
      className={cn(
        "inline-flex size-5 shrink-0 items-center justify-center rounded-full bg-orange-400 text-xs font-semibold text-slate-900",
        className
      )}
      {...props}
    />
  )
}

export { Badge }
