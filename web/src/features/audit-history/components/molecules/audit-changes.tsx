import { ArrowRight } from "lucide-react";
import DetailRow from "@/src/components/ui/molecules/detail-row";
import type { AuditChange, AuditEntry } from "../../utils/audit";

function Value({ value, previous = false }: { value: string | null; previous?: boolean }) {
  if (value === null) return <span className="text-ink-muted italic">Empty</span>;
  return previous ? (
    <del className="text-ink-muted decoration-ink-muted/60">
      <span className="sr-only">from </span>
      {value}
    </del>
  ) : (
    <span className="font-semibold text-ink">{value}</span>
  );
}

function ChangeValue({ change, kind }: { change: AuditChange; kind: AuditEntry["changeKind"] }) {
  if (kind === "created") return <Value value={change.after} />;
  return (
    <span className="inline-flex flex-wrap items-baseline gap-x-2 gap-y-0.5 break-words">
      <Value value={change.before} previous />
      <ArrowRight aria-hidden="true" className="size-3.5 shrink-0 self-center text-ink-muted" strokeWidth={2.25} />
      <span className="sr-only">to </span>
      <Value value={change.after} />
    </span>
  );
}

// The before/after snapshots, as a field-by-field list. Updates show only what changed.
export default function AuditChanges({ entry }: { entry: AuditEntry }) {
  if (!entry.changeKind) return null;
  const heading = entry.changeKind === "created" ? "Recorded values" : "Changes";

  return (
    <section aria-labelledby="audit-changes-heading" className="mt-6">
      <h4 id="audit-changes-heading" className="mb-1 flex items-baseline justify-between text-sm font-semibold text-ink">
        {heading}
        <span className="text-[0.8125rem] font-normal text-ink-muted tabular-nums">
          {entry.changes.length} {entry.changes.length === 1 ? "field" : "fields"}
        </span>
      </h4>
      {entry.changes.length > 0 ? (
        <dl>
          {entry.changes.map((change) => (
            <DetailRow key={change.field} label={change.label}>
              <ChangeValue change={change} kind={entry.changeKind} />
            </DetailRow>
          ))}
        </dl>
      ) : (
        <p className="border-t border-hairline py-3 text-sm text-ink-muted">No recorded fields changed.</p>
      )}
    </section>
  );
}
