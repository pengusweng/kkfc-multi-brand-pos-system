import * as React from "react"
import { cn } from "cn"

type AvatarProps = React.ComponentProps<"span"> & { name: string }

function Avatar({ name, className, ...props }: AvatarProps) {
  return (
    <span
      aria-hidden="true"
      className={cn(
        "inline-flex size-8 shrink-0 items-center justify-center rounded-full bg-primary text-sm font-semibold text-primary-foreground",
        className
      )}
      {...props}
    >
      {name.charAt(0).toUpperCase()}
    </span>
  )
}

export { Avatar }
