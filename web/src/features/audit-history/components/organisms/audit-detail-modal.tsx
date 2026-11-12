"use client";

import type { ReactNode } from "react";
import { X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Dialog, DialogClose, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import DetailRow from "@/src/components/ui/molecules/detail-row";
import { formatAuditTimeFull, type AuditEntry } from "../../utils/audit";
import AuditActorIdentity from "../molecules/audit-actor-identity";
import AuditChanges from "../molecules/audit-changes";

type AuditDetailModalProps = {
  entry: AuditEntry | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
};

// DESIGN.md › Elevation: dialogs get Shadow 3. Shadows vanish on the dark
// surface, so dark mode swaps it for a hairline edge instead of stacking both.
const SURFACE =
  "shadow-[0_8px_24px_rgba(25,41,62,0.14),0_2px_8px_rgba(25,41,62,0.08)] dark:shadow-none dark:ring-1 dark:ring-hairline";

// Identifiers and machine codes: selectable in one click, wrapped anywhere.
function Code({ children }: { children: ReactNode }) {
  return <span className="font-mono text-xs break-all text-ink-muted select-all">{children}</span>;
}

// A human label with the stored value underneath for cross-referencing logs.
function Labelled({ label, code }: { label: string; code: string }) {
  return (
    <span className="flex flex-col gap-0.5">
      <span>{label}</span>
      <Code>{code}</Code>
    </span>
  );
}

export default function AuditDetailModal({ entry, open, onOpenChange }: AuditDetailModalProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent
        showCloseButton={false}
        className={`flex max-h-[calc(100dvh-2rem)] flex-col gap-0 overflow-hidden rounded-xl bg-card p-0 text-ink ring-0 sm:max-w-lg ${SURFACE}`}
      >
        <DialogHeader className="flex-row items-center justify-between gap-4 border-b border-hairline py-3 pr-3 pl-6">
          <DialogTitle className="text-base font-semibold text-ink">Audit Log</DialogTitle>
          <DialogClose
            render={<Button variant="ghost" size="icon-lg" className="size-10 text-ink-muted hover:text-ink" />}
          >
            <X aria-hidden="true" className="size-5" />
            <span className="sr-only">Close</span>
          </DialogClose>
        </DialogHeader>

        {entry ? (
          <div className="overflow-y-auto px-6 pt-5 pb-6">
            <AuditActorIdentity entry={entry} />

            <dl className="mt-5">
              <DetailRow label="Action">
                <Labelled label={entry.action} code={entry.actionCode} />
              </DetailRow>
              {entry.reason ? (
                <DetailRow label="Reason">
                  <Labelled label={entry.reason.text} code={entry.reason.code} />
                </DetailRow>
              ) : null}
              <DetailRow label="Time">
                <time dateTime={entry.time}>
                  {formatAuditTimeFull(entry.time)}
                </time>
              </DetailRow>
              <DetailRow label="Record">
                <span className="flex flex-col gap-0.5">
                  <span>{entry.entity}</span>
                  {entry.entityId ? <Code>{entry.entityId}</Code> : <span className="text-ink-muted">No specific record</span>}
                </span>
              </DetailRow>
            </dl>

            <AuditChanges entry={entry} />

            <dl className="mt-6">
              <DetailRow label="Request ID">
                {entry.requestId ? <Code>{entry.requestId}</Code> : <span className="text-ink-muted">Not recorded</span>}
              </DetailRow>
              <DetailRow label="Log ID">
                <Code>{entry.id}</Code>
              </DetailRow>
            </dl>
          </div>
        ) : null}
      </DialogContent>
    </Dialog>
  );
}
