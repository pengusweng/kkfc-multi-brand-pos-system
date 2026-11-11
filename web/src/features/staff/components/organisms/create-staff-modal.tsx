"use client";

import { ChevronDown, CircleAlert, LoaderCircle, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/src/components/ui/atoms/input";
import { usePin } from "@/src/features/pin/hooks/usePin";
import { useCreateStaff } from "../../hooks/useCreateStaff";
import { CREATABLE_ROLES } from "../../schemas/createStaffSchema";
import type { User } from "../../schemas/userSchema";
import { fieldError } from "../../utils/form";
import { ROLE_LABEL } from "../../utils/staff";
import FormField, { fieldMessageId } from "../molecules/form-field";
import PasswordInput from "../molecules/password-input";

type CreateStaffModalProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onCreated: (user: User) => void;
};

const SURFACE =
  "shadow-[0_8px_24px_rgba(25,41,62,0.14),0_2px_8px_rgba(25,41,62,0.08)] dark:shadow-none dark:ring-1 dark:ring-hairline";

export default function CreateStaffModal({ open, onOpenChange, onCreated }: CreateStaffModalProps) {
  const { isPrompting } = usePin();
  const { form, serverError, reset } = useCreateStaff(onCreated);

  return (
    <Dialog
      open={open}
      onOpenChange={(next) => {
        // The PIN prompt sits on top of this dialog; its Escape and clicks must not close the form beneath it.
        if (!next && (isPrompting || form.state.isSubmitting)) return;
        onOpenChange(next);
      }}
      onOpenChangeComplete={(isOpen) => {
        if (!isOpen) reset();
      }}
    >
      <DialogContent
        showCloseButton={false}
        className={`flex max-h-[calc(100dvh-2rem)] flex-col gap-0 overflow-hidden rounded-xl bg-card p-0 text-ink ring-0 sm:max-w-lg ${SURFACE}`}
      >
        <form
          noValidate
          className="flex min-h-0 flex-1 flex-col"
          onSubmit={(e) => {
            e.preventDefault();
            void form.handleSubmit();
          }}
        >
          <DialogHeader className="flex-row items-center justify-between gap-4 border-b border-hairline py-3 pr-3 pl-6">
            <DialogTitle className="text-base font-semibold text-ink">Add staff account</DialogTitle>
            <DialogClose
              render={<Button type="button" variant="ghost" size="icon-lg" className="size-10 text-ink-muted hover:text-ink" />}
            >
              <X aria-hidden="true" className="size-5" />
              <span className="sr-only">Close</span>
            </DialogClose>
          </DialogHeader>

          <div className="flex min-h-0 flex-col gap-5 overflow-y-auto px-6 pt-5 pb-6">
            <DialogDescription className="text-sm leading-relaxed text-ink-muted">
              They sign in with this username and password. You can change their details later.
            </DialogDescription>

            <div className="grid gap-5 sm:grid-cols-2 sm:gap-4">
              <form.Field name="first_name">
                {(field) => {
                  const error = fieldError(field.state.meta);
                  return (
                    <FormField id="create-first-name" label="First name" error={error}>
                      <Input
                        id="create-first-name"
                        autoComplete="off"
                        value={field.state.value}
                        onChange={(e) => field.handleChange(e.target.value)}
                        onBlur={field.handleBlur}
                        aria-invalid={Boolean(error)}
                        aria-describedby={fieldMessageId("create-first-name", Boolean(error))}
                      />
                    </FormField>
                  );
                }}
              </form.Field>

              <form.Field name="last_name">
                {(field) => {
                  const error = fieldError(field.state.meta);
                  return (
                    <FormField id="create-last-name" label="Last name" error={error}>
                      <Input
                        id="create-last-name"
                        autoComplete="off"
                        value={field.state.value}
                        onChange={(e) => field.handleChange(e.target.value)}
                        onBlur={field.handleBlur}
                        aria-invalid={Boolean(error)}
                        aria-describedby={fieldMessageId("create-last-name", Boolean(error))}
                      />
                    </FormField>
                  );
                }}
              </form.Field>
            </div>

            <form.Field name="username">
              {(field) => {
                const error = fieldError(field.state.meta);
                return (
                  <FormField id="create-username" label="Username" hint="Up to 16 characters." error={error}>
                    <Input
                      id="create-username"
                      autoComplete="off"
                      autoCapitalize="none"
                      spellCheck={false}
                      maxLength={16}
                      value={field.state.value}
                      onChange={(e) => field.handleChange(e.target.value)}
                      onBlur={field.handleBlur}
                      aria-invalid={Boolean(error)}
                      aria-describedby="create-username-message"
                    />
                  </FormField>
                );
              }}
            </form.Field>

            <form.Field name="role">
              {(field) => {
                const error = fieldError(field.state.meta);
                return (
                  <FormField id="create-role" label="Role" error={error}>
                    <div className="relative">
                      <select
                        id="create-role"
                        value={field.state.value}
                        onChange={(e) => field.handleChange(e.target.value)}
                        onBlur={field.handleBlur}
                        aria-invalid={Boolean(error)}
                        aria-describedby={fieldMessageId("create-role", Boolean(error))}
                        className={`h-12 w-full cursor-pointer appearance-none rounded-lg border border-input bg-field pr-11 pl-3 text-base outline-none transition-colors focus-visible:border-primary focus-visible:ring-2 focus-visible:ring-primary/15 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 ${
                          field.state.value ? "text-ink" : "text-ink-muted"
                        }`}
                      >
                        <option value="" disabled>
                          Select a role
                        </option>
                        {CREATABLE_ROLES.map((role) => (
                          <option key={role} value={role} className="text-ink">
                            {ROLE_LABEL[role]}
                          </option>
                        ))}
                      </select>
                      <ChevronDown
                        aria-hidden="true"
                        className="pointer-events-none absolute top-1/2 right-4 size-4 -translate-y-1/2 text-ink-muted"
                      />
                    </div>
                  </FormField>
                );
              }}
            </form.Field>

            <form.Field name="password">
              {(field) => {
                const error = fieldError(field.state.meta);
                return (
                  <FormField id="create-password" label="Password" hint="8 to 32 characters." error={error}>
                    <PasswordInput
                      id="create-password"
                      autoComplete="new-password"
                      value={field.state.value}
                      onChange={(e) => field.handleChange(e.target.value)}
                      onBlur={field.handleBlur}
                      aria-invalid={Boolean(error)}
                      aria-describedby="create-password-message"
                    />
                  </FormField>
                );
              }}
            </form.Field>

            {serverError ? (
              <p
                role="alert"
                className="flex items-start gap-2.5 rounded-lg bg-destructive/8 px-3 py-2.5 text-sm leading-5 text-danger-ink dark:text-destructive"
              >
                <CircleAlert aria-hidden="true" className="mt-px size-4 shrink-0 text-destructive" />
                {serverError}
              </p>
            ) : null}
          </div>

          <DialogFooter className="mx-0 mb-0 border-hairline bg-transparent px-6 py-4">
            <DialogClose
              render={<Button type="button" variant="outline" size="lg" className="h-10 px-4 font-semibold" />}
            >
              Cancel
            </DialogClose>
            <form.Subscribe selector={(state) => state.isSubmitting}>
              {(submitting) => (
                <Button type="submit" size="lg" className="h-10 px-4 font-semibold" disabled={submitting} aria-busy={submitting}>
                  {submitting ? <LoaderCircle aria-hidden="true" className="animate-spin" /> : null}
                  {submitting ? "Creating…" : "Create account"}
                </Button>
              )}
            </form.Subscribe>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
