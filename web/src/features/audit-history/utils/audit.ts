export type AuditOutcome = "success" | "denied" | "fail";

export type AuditEntry = {
  id: string;
  time: string; // ISO timestamp
  actor: string;
  action: string;
  outcome: AuditOutcome;
};

export const AUDIT_PAGE_SIZE = 15;

// Pinned to Manila so server and client render the same string (no hydration mismatch).
const TIME_FORMAT = new Intl.DateTimeFormat("en-PH", {
  timeZone: "Asia/Manila",
  month: "short",
  day: "numeric",
  year: "numeric",
  hour: "numeric",
  minute: "2-digit",
});

export function formatAuditTime(iso: string) {
  return TIME_FORMAT.format(new Date(iso));
}

// Placeholder data until the audit endpoint is wired up.
const ACTORS = ["Maria Santos", "Juan dela Cruz", "Angela Reyes", "Paolo Garcia", "Bea Mendoza", "Carlo Villanueva"];
const ACTIONS = [
  "Signed in",
  "Created staff account",
  "Updated staff account",
  "Deactivated staff account",
  "Updated menu item",
  "Uploaded menu image",
  "Voided order",
  "Viewed audit trail",
];
const OUTCOMES: AuditOutcome[] = ["success", "success", "success", "success", "denied", "success", "fail", "success", "success"];

const START = Date.parse("2026-11-12T09:30:00+08:00");

export const MOCK_AUDIT_ENTRIES: AuditEntry[] = Array.from({ length: 87 }, (_, i) => ({
  id: `audit-${i + 1}`,
  time: new Date(START - i * (11 + ((i * 7) % 23)) * 60_000).toISOString(),
  actor: ACTORS[(i * 5) % ACTORS.length],
  action: ACTIONS[(i * 3) % ACTIONS.length],
  outcome: OUTCOMES[i % OUTCOMES.length],
}));
