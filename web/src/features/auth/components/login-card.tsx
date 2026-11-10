"use client";

import { useState, type CSSProperties } from "react";
import { CircleAlert, Eye, EyeOff, LoaderCircle } from "lucide-react";
import { Label } from "@/components/ui/label";
import { Input } from "@/src/components/ui/atoms/input";
import { Button } from "@/components/ui/button";
import type { useLogin } from "../hooks/useLogin";

type LoginCardProps = Pick<ReturnType<typeof useLogin>, "form" | "serverError"> & {
  redirecting?: boolean;
};

// Each block rises in slightly after the one above it.
const rise = (step: number): CSSProperties => ({ animationDelay: `${180 + step * 70}ms` });

export default function LoginCard({ form, serverError, redirecting = false }: LoginCardProps) {
  const [showPassword, setShowPassword] = useState(false);

  return (
    <section aria-labelledby="login-title" className="w-full max-w-sm lg:-mt-8">
      <header className="motion-safe:animate-rise" style={rise(0)}>
        <h1 id="login-title" className="text-3xl leading-tight font-semibold tracking-[-0.02em] text-ink">
          Sign in
        </h1>
        <p className="mt-2 text-base leading-6 text-ink-muted">
          Use your staff username and password.
        </p>
      </header>

      <form
        id="login-form"
        noValidate
        className="mt-8 flex flex-col gap-5"
        onSubmit={(event) => {
          event.preventDefault();
          void form.handleSubmit();
        }}
      >
        <form.Field name="username">
          {(field) => {
            const invalid = field.state.meta.isTouched && !field.state.meta.isValid;

            return (
              <div className="grid gap-2 motion-safe:animate-rise" style={rise(1)}>
                <Label htmlFor={field.name} className="leading-5 text-ink">Username</Label>
                <Input
                  id={field.name}
                  name={field.name}
                  type="text"
                  autoComplete="username"
                  autoCapitalize="none"
                  spellCheck={false}
                  value={field.state.value}
                  onChange={(event) => field.handleChange(event.target.value)}
                  onBlur={field.handleBlur}
                  aria-invalid={invalid}
                  aria-describedby={invalid ? "username-error" : undefined}
                  placeholder="Enter your username"
                  required
                />
                {invalid && (
                  <p id="username-error" role="alert" className="text-sm text-destructive">
                    {field.state.meta.errors.map((error) => error?.message).join(" ")}
                  </p>
                )}
              </div>
            );
          }}
        </form.Field>

        <form.Field name="password">
          {(field) => {
            const invalid = field.state.meta.isTouched && !field.state.meta.isValid;

            return (
              <div className="grid gap-2 motion-safe:animate-rise" style={rise(2)}>
                <Label htmlFor={field.name} className="leading-5 text-ink">Password</Label>
                <div className="relative">
                  <Input
                    id={field.name}
                    name={field.name}
                    type={showPassword ? "text" : "password"}
                    autoComplete="current-password"
                    className="pr-14"
                    value={field.state.value}
                    onChange={(event) => field.handleChange(event.target.value)}
                    onBlur={field.handleBlur}
                    aria-invalid={invalid}
                    aria-describedby={invalid ? "password-error" : undefined}
                    placeholder="Enter your password"
                    required
                  />
                  <Button
                    type="button"
                    variant="ghost"
                    size="icon"
                    className="absolute top-0.5 right-0.5 size-11 cursor-pointer text-ink-muted hover:bg-surface-hover hover:text-ink"
                    aria-label={showPassword ? "Hide password" : "Show password"}
                    aria-controls="password"
                    aria-pressed={showPassword}
                    onClick={() => setShowPassword((visible) => !visible)}
                  >
                    {showPassword ? <EyeOff className="size-5" aria-hidden="true" /> : <Eye className="size-5" aria-hidden="true" />}
                  </Button>
                </div>
                {invalid && (
                  <p id="password-error" role="alert" className="text-sm text-destructive">
                    {field.state.meta.errors.map((error) => error?.message).join(" ")}
                  </p>
                )}
              </div>
            );
          }}
        </form.Field>

        {serverError && (
          <p
            role="alert"
            className="flex items-start gap-2.5 rounded-lg bg-destructive/8 px-3 py-2.5 text-sm leading-5 text-danger-ink motion-safe:animate-rise"
          >
            <CircleAlert aria-hidden="true" className="mt-px size-4 shrink-0 text-destructive" />
            {serverError}
          </p>
        )}

        <form.Subscribe selector={(state) => state.isSubmitting}>
          {(isSubmitting) => {
            const busy = isSubmitting || redirecting;

            return (
              <Button
                type="submit"
                disabled={busy}
                aria-busy={busy}
                className="mt-1 h-12 w-full cursor-pointer text-base font-semibold motion-safe:animate-rise disabled:opacity-80"
                style={rise(3)}
              >
                {busy && <LoaderCircle aria-hidden="true" className="size-5 animate-spin" />}
                {redirecting ? "Opening dashboard…" : isSubmitting ? "Signing in…" : "Sign In"}
              </Button>
            );
          }}
        </form.Subscribe>
      </form>
    </section>
  );
}
