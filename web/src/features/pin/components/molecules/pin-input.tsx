"use client";

import { useState, type Ref } from "react";

export const PIN_LENGTH = 4;

type PinInputProps = {
  ref?: Ref<HTMLInputElement>;
  value: string;
  onChange: (value: string) => void;
  onComplete?: (value: string) => void;
  invalid?: boolean;
  disabled?: boolean;
  describedBy?: string;
};

// One real input stretched invisibly over four drawn slots: typing, deleting,
// pasting and the numeric keypad all behave natively, the slots are visual only.
export default function PinInput({ ref, value, onChange, onComplete, invalid, disabled, describedBy }: PinInputProps) {
  const [focused, setFocused] = useState(false);
  const active = Math.min(value.length, PIN_LENGTH - 1);

  return (
    <div className="relative mx-auto w-fit">
      <input
        ref={ref}
        type="password"
        inputMode="numeric"
        autoComplete="one-time-code"
        pattern="[0-9]*"
        maxLength={PIN_LENGTH}
        value={value}
        disabled={disabled}
        aria-label={`${PIN_LENGTH}-digit PIN`}
        aria-invalid={invalid || undefined}
        aria-describedby={describedBy}
        onFocus={() => setFocused(true)}
        onBlur={() => setFocused(false)}
        onChange={(e) => {
          const next = e.target.value.replace(/\D/g, "").slice(0, PIN_LENGTH);
          onChange(next);
          if (next.length === PIN_LENGTH) onComplete?.(next);
        }}
        className="absolute inset-0 z-10 cursor-text opacity-0 disabled:cursor-not-allowed"
      />
      <div aria-hidden="true" className="flex gap-3">
        {Array.from({ length: PIN_LENGTH }, (_, i) => {
          const filled = i < value.length;
          const current = focused && !disabled && i === active;
          return (
            <span
              key={i}
              className={`grid h-14 w-12 place-items-center rounded-[10px] border bg-field transition-[border-color,box-shadow] duration-150 ${
                invalid
                  ? "border-destructive"
                  : current
                    ? "border-primary ring-2 ring-primary/15"
                    : "border-hairline"
              } ${disabled ? "opacity-60" : ""}`}
            >
              {filled ? <span className="size-3 rounded-full bg-ink" /> : null}
            </span>
          );
        })}
      </div>
    </div>
  );
}
