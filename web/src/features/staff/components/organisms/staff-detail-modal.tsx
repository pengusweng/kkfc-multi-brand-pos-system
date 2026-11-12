"use client";

import { Ban, CircleAlert, Pencil, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Dialog, DialogClose, DialogContent, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { usePin } from "@/src/features/pin/hooks/usePin";
import type { StaffMember } from "../../utils/staff";
import DetailRow from "@/src/components/ui/molecules/detail-row";
import StaffIdentity from "../molecules/staff-identity";

type StaffDetailModalProps = {
  member: StaffMember | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onEdit?: (member: StaffMember) => void;
  onDeactivate?: (member: StaffMember) => void;
  /** Shown above the footer, e.g. when deactivating fails. */
  error?: string | null;
};

// DESIGN.md › Elevation: dialogs get Shadow 3. Shadows vanish on the dark
// surface, so dark mode swaps it for a hairline edge instead of stacking both.
const SURFACE =
  "shadow-[0_8px_24px_rgba(25,41,62,0.14),0_2px_8px_rgba(25,41,62,0.08)] dark:shadow-none dark:ring-1 dark:ring-hairline";

export default function StaffDetailModal({
  member,
  open,
  onOpenChange,
  onEdit,
  onDeactivate,
  error,
}: StaffDetailModalProps) {
  const { isPrompting } = usePin();

  return (
    <Dialog
      open={open}
      onOpenChange={(next) => {
        // The PIN prompt sits on top of this dialog; its Escape and clicks must not close the profile beneath it.
        if (!next && isPrompting) return;
        onOpenChange(next);
      }}
    >
      <DialogContent
        showCloseButton={false}
        className={`flex max-h-[calc(100dvh-2rem)] flex-col gap-0 overflow-hidden rounded-xl bg-card p-0 text-ink ring-0 sm:max-w-lg ${SURFACE}`}
      >
        <DialogHeader className="flex-row items-center justify-between gap-4 border-b border-hairline py-3 pr-3 pl-6">
          <DialogTitle className="text-base font-semibold text-ink">Staff account profile</DialogTitle>
          <DialogClose
            render={<Button variant="ghost" size="icon-lg" className="size-10 text-ink-muted hover:text-ink" />}
          >
            <X aria-hidden="true" className="size-5" />
            <span className="sr-only">Close</span>
          </DialogClose>
        </DialogHeader>

        {member ? (
          <div className={`overflow-y-auto px-6 pt-5 ${member.status === "active" ? "pb-3" : "pb-6"}`}>
            <StaffIdentity member={member} />

            <dl className="mt-5">
              <DetailRow label="Role">{member.role}</DetailRow>
              <DetailRow label="Created">{member.createdAt}</DetailRow>
              <DetailRow label="Last updated">{member.modifiedAt}</DetailRow>
              <DetailRow label="Account ID">
                <span className="font-mono text-xs break-all text-ink-muted select-all">{member.id}</span>
              </DetailRow>
            </dl>
          </div>
        ) : null}

        {error ? (
          <p
            role="alert"
            className="mx-6 mb-4 flex items-start gap-2.5 rounded-lg bg-destructive/8 px-3 py-2.5 text-sm leading-5 text-danger-ink dark:text-destructive"
          >
            <CircleAlert aria-hidden="true" className="mt-px size-4 shrink-0 text-destructive" />
            {error}
          </p>
        ) : null}

        {/* The API only edits and deactivates active accounts (and can't reactivate),
            so inactive accounts are view-only. */}
        {member?.status === "active" ? (
          <DialogFooter className="mx-0 mb-0 border-hairline bg-transparent px-6 py-4 sm:justify-between">
            <Button
              variant="destructive"
              size="lg"
              className="h-10 px-4 font-semibold cursor-pointer"
              onClick={() => onDeactivate?.(member)}
            >
              <Ban aria-hidden="true" />
              Deactivate
            </Button>
            <Button size="lg" className="h-10 px-4 font-semibold cursor-pointer" onClick={() => onEdit?.(member)}>
              <Pencil aria-hidden="true" />
              Edit
            </Button>
          </DialogFooter>
        ) : null}
      </DialogContent>
    </Dialog>
  );
}
