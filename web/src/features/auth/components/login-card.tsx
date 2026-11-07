"use client";

import { useState } from "react";
import { Eye, EyeOff } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Input } from "@/src/components/ui/atoms/input";
import { Button } from "@/components/ui/button";
import type { useLogin } from "../hooks/useLogin";

type LoginCardProps = Pick<ReturnType<typeof useLogin>, "form" | "serverError">;

export default function LoginCard({ form, serverError }: LoginCardProps) {
  const [showPassword, setShowPassword] = useState(false);

  return(
    <Card className="w-full self-center justify-self-center gap-8 rounded-none ring-0 [--card-spacing:--spacing(6)] lg:max-w-132 lg:[--card-spacing:--spacing(12)]">
      <CardHeader>
        <CardTitle>
          <h1 className="text-2xl leading-8 font-semibold tracking-tight">Sign In</h1>
        </CardTitle>
      </CardHeader>
      <CardContent>
        <form
          id="login-form"
          noValidate
          onSubmit={(event) => {
            event.preventDefault();
            void form.handleSubmit();
          }}
        >
          <div className="flex flex-col gap-6">
            <form.Field name="username">
              {(field) => {
                const invalid = field.state.meta.isTouched && !field.state.meta.isValid;

                return (
                  <div className="grid gap-2">
                    <Label htmlFor={field.name} className="leading-5">Username</Label>
                    <Input
                      id={field.name}
                      name={field.name}
                      type="text"
                      autoComplete="username"
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
                  <div className="grid gap-2">
                    <Label htmlFor={field.name} className="leading-5">Password</Label>
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
                        className="absolute top-0.5 right-0.5 size-11 cursor-pointer"
                        aria-label={showPassword ? "Hide password" : "Show password"}
                        aria-controls="password"
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
              <p role="alert" className="text-sm text-destructive">{serverError}</p>
            )}

            <form.Subscribe selector={(state) => state.isSubmitting}>
              {(isSubmitting) => (
                <Button
                  type="submit"
                  disabled={isSubmitting}
                  className="h-12 w-full cursor-pointer text-base font-semibold"
                >
                  {isSubmitting ? "Signing in…" : "Sign In"}
                </Button>
              )}
            </form.Subscribe>
          </div>
        </form>
      </CardContent>
    </Card>
  )
}
