"use client";

import { Ban, Pencil, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Dialog, DialogClose, DialogContent, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import type { StaffMember } from "../../utils/staff";
import DetailRow from "../molecules/detail-row";
import StaffIdentity from "../molecules/staff-identity";

type StaffDetailModalProps = {
  member: StaffMember | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onEdit?: (member: StaffMember) => void;
  onDeactivate?: (member: StaffMember) => void;
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
}: StaffDetailModalProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
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
          <div className="overflow-y-auto px-6 pt-5 pb-3">
            <StaffIdentity member={member} />

            <dl className="mt-5">
              <DetailRow label="Role">{member.role}</DetailRow>
              <DetailRow label="Created">
                <span className="tabular-nums">{member.createdAt}</span>
              </DetailRow>
              <DetailRow label="Last updated">
                <span className="tabular-nums">{member.modifiedAt}</span>
              </DetailRow>
              <DetailRow label="Account ID">
                <span className="font-mono text-xs break-all text-ink-muted select-all">{member.id}</span>
              </DetailRow>
            </dl>
          </div>
        ) : null}

        <DialogFooter className="mx-0 mb-0 border-hairline bg-transparent px-6 py-4 sm:justify-between">
          {/* The API can deactivate but not reactivate, so inactive accounts get no button. */}
          {member?.status === "active" ? (
            <Button
              variant="destructive"
              size="lg"
              className="h-10 px-4 font-semibold cursor-pointer"
              onClick={() => onDeactivate?.(member)}
            >
              <Ban aria-hidden="true" />
              Deactivate
            </Button>
          ) : (
            <span aria-hidden="true" className="hidden sm:block" />
          )}
          <Button
            size="lg"
            className="h-10 px-4 font-semibold cursor-pointer"
            disabled={!member}
            onClick={() => member && onEdit?.(member)}
          >
            <Pencil aria-hidden="true" />
            Edit
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
