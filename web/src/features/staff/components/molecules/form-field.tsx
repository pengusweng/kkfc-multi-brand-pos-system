import type { ReactNode } from "react";
import { Label } from "@/components/ui/label";

type FormFieldProps = {
  id: string;
  label: string;
  /** Shown under the control until there is an error to show instead. */
  hint?: string;
  error?: string;
  children: ReactNode;
};

// Label, control, then one message line: the hint, or the error once there is one.
// The control should point aria-describedby at `${id}-message`.
export default function FormField({ id, label, hint, error, children }: FormFieldProps) {
  const message = error ?? hint;
  return (
    <div className="grid gap-2">
      <Label htmlFor={id} className="leading-5 font-semibold text-ink">
        {label}
      </Label>
      {children}
      {message ? (
        <p
          id={`${id}-message`}
          role={error ? "alert" : undefined}
          className={`text-sm leading-5 ${error ? "text-danger-ink dark:text-destructive" : "text-ink-muted"}`}
        >
          {message}
        </p>
      ) : null}
    </div>
  );
}

export const fieldMessageId = (id: string, show: boolean) => (show ? `${id}-message` : undefined);
