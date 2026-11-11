"use client";

import { CircleAlert, LoaderCircle, X } from "lucide-react";
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
import { changedFields, useEditStaff } from "../../hooks/useEditStaff";
import type { User } from "../../schemas/userSchema";
import { fieldError } from "../../utils/form";
import type { StaffMember } from "../../utils/staff";
import FormField, { fieldMessageId } from "../molecules/form-field";
import PasswordInput from "../molecules/password-input";

type EditStaffModalProps = {
  member: StaffMember | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSaved: (user: User) => void;
};

const SURFACE =
  "shadow-[0_8px_24px_rgba(25,41,62,0.14),0_2px_8px_rgba(25,41,62,0.08)] dark:shadow-none dark:ring-1 dark:ring-hairline";

export default function EditStaffModal({ member, open, onOpenChange, onSaved }: EditStaffModalProps) {
  const { isPrompting } = usePin();

  return (
    <Dialog
      open={open}
      onOpenChange={(next) => {
        // The PIN prompt sits on top of this dialog; its Escape and clicks must not close the form beneath it.
        if (!next && isPrompting) return;
        onOpenChange(next);
      }}
    >
      <DialogContent
        showCloseButton={false}
        className={`flex max-h-[calc(100dvh-2rem)] flex-col gap-0 overflow-hidden rounded-xl bg-card p-0 text-ink ring-0 sm:max-w-lg ${SURFACE}`}
      >
        {/* The dialog unmounts its content when closed, so every open starts from the saved values. */}
        {member ? <EditStaffForm member={member} onSaved={onSaved} /> : null}
      </DialogContent>
    </Dialog>
  );
}

function EditStaffForm({ member, onSaved }: { member: StaffMember; onSaved: (user: User) => void }) {
  const { form, serverError } = useEditStaff(member, onSaved);

  return (
    <form
      noValidate
      className="flex min-h-0 flex-1 flex-col"
      onSubmit={(e) => {
        e.preventDefault();
        void form.handleSubmit();
      }}
    >
      <DialogHeader className="flex-row items-center justify-between gap-4 border-b border-hairline py-3 pr-3 pl-6">
        <DialogTitle className="text-base font-semibold text-ink">Edit staff account</DialogTitle>
        <DialogClose
          render={<Button type="button" variant="ghost" size="icon-lg" className="size-10 text-ink-muted hover:text-ink" />}
        >
          <X aria-hidden="true" className="size-5" />
          <span className="sr-only">Close</span>
        </DialogClose>
      </DialogHeader>

      <div className="flex min-h-0 flex-col gap-5 overflow-y-auto px-6 pt-5 pb-6">
        <DialogDescription className="text-sm leading-relaxed text-ink-muted">
          Update {member.name}&apos;s details. Their role ({member.role}) can&apos;t be changed here.
        </DialogDescription>

        <div className="grid gap-5 sm:grid-cols-2 sm:gap-4">
          <form.Field name="first_name">
            {(field) => {
              const error = fieldError(field.state.meta);
              return (
                <FormField id="edit-first-name" label="First name" error={error}>
                  <Input
                    id="edit-first-name"
                    autoComplete="off"
                    value={field.state.value}
                    onChange={(e) => field.handleChange(e.target.value)}
                    onBlur={field.handleBlur}
                    aria-invalid={Boolean(error)}
                    aria-describedby={fieldMessageId("edit-first-name", Boolean(error))}
                  />
                </FormField>
              );
            }}
          </form.Field>

          <form.Field name="last_name">
            {(field) => {
              const error = fieldError(field.state.meta);
              return (
                <FormField id="edit-last-name" label="Last name" error={error}>
                  <Input
                    id="edit-last-name"
                    autoComplete="off"
                    value={field.state.value}
                    onChange={(e) => field.handleChange(e.target.value)}
                    onBlur={field.handleBlur}
                    aria-invalid={Boolean(error)}
                    aria-describedby={fieldMessageId("edit-last-name", Boolean(error))}
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
              <FormField id="edit-username" label="Username" hint="Up to 16 characters." error={error}>
                <Input
                  id="edit-username"
                  autoComplete="off"
                  autoCapitalize="none"
                  spellCheck={false}
                  maxLength={16}
                  value={field.state.value}
                  onChange={(e) => field.handleChange(e.target.value)}
                  onBlur={field.handleBlur}
                  aria-invalid={Boolean(error)}
                  aria-describedby="edit-username-message"
                />
              </FormField>
            );
          }}
        </form.Field>

        <form.Field name="password">
          {(field) => {
            const error = fieldError(field.state.meta);
            return (
              <FormField
                id="edit-password"
                label="New password"
                hint="Leave blank to keep their current password. 8 to 32 characters."
                error={error}
              >
                <PasswordInput
                  id="edit-password"
                  autoComplete="new-password"
                  placeholder="Unchanged"
                  value={field.state.value}
                  onChange={(e) => field.handleChange(e.target.value)}
                  onBlur={field.handleBlur}
                  aria-invalid={Boolean(error)}
                  aria-describedby="edit-password-message"
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
        <DialogClose render={<Button type="button" variant="outline" size="lg" className="h-10 px-4 font-semibold" />}>
          Cancel
        </DialogClose>
        <form.Subscribe
          selector={(state) => ({
            submitting: state.isSubmitting,
            changed: Object.keys(changedFields(member, state.values)).length > 0,
          })}
        >
          {({ submitting, changed }) => (
            <Button
              type="submit"
              size="lg"
              className="h-10 px-4 font-semibold"
              disabled={submitting || !changed}
              aria-busy={submitting}
            >
              {submitting ? <LoaderCircle aria-hidden="true" className="animate-spin" /> : null}
              {submitting ? "Saving…" : "Save changes"}
            </Button>
          )}
        </form.Subscribe>
      </DialogFooter>
    </form>
  );
}
