"use client";

import { useState, type ComponentProps } from "react";
import { Eye, EyeOff } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/src/components/ui/atoms/input";

// Same show/hide control as the sign-in form.
export default function PasswordInput({ id, className = "", ...props }: Omit<ComponentProps<typeof Input>, "type">) {
  const [visible, setVisible] = useState(false);
  return (
    <div className="relative">
      <Input id={id} type={visible ? "text" : "password"} className={`pr-14 ${className}`} {...props} />
      <Button
        type="button"
        variant="ghost"
        size="icon"
        className="absolute top-0.5 right-0.5 size-11 cursor-pointer text-ink-muted hover:bg-surface-hover hover:text-ink"
        aria-label={visible ? "Hide password" : "Show password"}
        aria-controls={id}
        aria-pressed={visible}
        onClick={() => setVisible((v) => !v)}
      >
        {visible ? <EyeOff className="size-5" aria-hidden="true" /> : <Eye className="size-5" aria-hidden="true" />}
      </Button>
    </div>
  );
}
