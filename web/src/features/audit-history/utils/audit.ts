import { ROLE_LABEL } from "@/src/features/staff/utils/staff";
import type { UserRole } from "@/src/features/staff/schemas/userSchema";
import type { AuditLog, AuditOutcomeCode, AuditSnapshot } from "../schemas/auditLogSchema";

export type AuditOutcome = "success" | "denied" | "fail";

export type AuditActor = {
  id: string;
  name: string;
  username: string;
  /** Display label, e.g. "Kitchen Head". */
  role: string;
};

export type AuditChange = {
  field: string;
  label: string;
  /** Display-ready; null means the field was empty. */
  before: string | null;
  after: string | null;
};

export type AuditEntry = {
  id: string;
  /** ISO timestamp. */
  time: string;
  /** null when nobody was signed in, e.g. a failed sign-in. */
  actor: AuditActor | null;
  action: string;
  actionCode: string;
  entity: string;
  entityType: string;
  entityId: string | null;
  outcome: AuditOutcome;
  reason: { code: string; text: string } | null;
  /** "created" lists every recorded field; "updated" only the ones that changed. */
  changeKind: "created" | "updated" | null;
  changes: AuditChange[];
  requestId: string | null;
};

export const AUDIT_PAGE_SIZE = 15;

const OUTCOME: Record<AuditOutcomeCode, AuditOutcome> = { SUCCESS: "success", DENIED: "denied", FAILED: "fail" };

// "MENU_ITEM_UPDATED" → "Menu item updated"; the fallback for anything not listed below.
function humanize(code: string) {
  const words = code.toLowerCase().replaceAll("_", " ");
  return words.charAt(0).toUpperCase() + words.slice(1);
}

const ACTION_LABEL: Record<string, string> = {
  AUTH_LOGIN: "Signed in",
  AUTH_LOGOUT: "Signed out",
  AUTH_LOGOUT_ALL: "Signed out everywhere",
  PIN_CREATED: "Set up action PIN",
  PIN_UPDATED: "Changed action PIN",
  USER_CREATED: "Created staff account",
  USER_UPDATED: "Updated staff account",
  USER_DEACTIVATED: "Deactivated staff account",
  USER_VIEWED: "Viewed staff account",
  USERS_LISTED: "Viewed staff list",
  BRAND_CREATED: "Created brand",
  BRAND_UPDATED: "Updated brand",
  BRAND_DEACTIVATED: "Deactivated brand",
  MENU_CATALOG_ENTRY_CREATED: "Added to menu catalog",
  MENU_ITEM_CREATED: "Created menu item",
  MENU_ITEM_UPDATED: "Updated menu item",
  MENU_ITEM_AVAILABILITY_CHANGED: "Changed menu item availability",
  MENU_ITEM_DEACTIVATED: "Deactivated menu item",
  MENU_ITEM_REACTIVATED: "Reactivated menu item",
  MENU_ITEM_CHANNEL_CREATED: "Added channel price",
  MENU_ITEM_CHANNEL_UPDATED: "Updated channel price",
  MENU_ITEM_CHANNEL_DEACTIVATED: "Deactivated channel price",
  MENU_ITEM_CHANNEL_REACTIVATED: "Reactivated channel price",
  MENU_ITEM_MODIFIER_CREATED: "Attached modifier to menu item",
  MENU_ITEM_MODIFIER_UPDATED: "Updated menu item modifier",
  MENU_ITEM_MODIFIER_DEACTIVATED: "Deactivated menu item modifier",
  MENU_ITEM_MODIFIER_REACTIVATED: "Reactivated menu item modifier",
  MODIFIER_CREATED: "Created modifier",
  MODIFIER_UPDATED: "Updated modifier",
  MODIFIER_DEACTIVATED: "Deactivated modifier",
  MODIFIER_REACTIVATED: "Reactivated modifier",
  ORDER_CREATED: "Created order",
  ORDER_CONFIRMED: "Confirmed order",
  ORDER_CANCELLED: "Cancelled order",
  KITCHEN_TICKET_PREPARER_ASSIGNED: "Assigned ticket preparer",
  KITCHEN_TICKET_CHECKER_ASSIGNED: "Assigned ticket checker",
  KITCHEN_TICKET_ACKNOWLEDGED: "Acknowledged ticket",
  KITCHEN_TICKET_PREPARATION_STARTED: "Started preparing ticket",
  KITCHEN_TICKET_SENT_FOR_CHECKING: "Sent ticket for checking",
  KITCHEN_TICKET_CHECK_STARTED: "Started checking ticket",
  KITCHEN_QC_PASSED: "Passed quality check",
  KITCHEN_QC_REJECTED: "Rejected quality check",
  KITCHEN_TICKET_HANDED_OVER: "Handed over ticket",
  ASSET_UPLOADED: "Uploaded image",
  ASSET_DOWNLOAD_URL_ISSUED: "Opened image link",
  // No longer recorded, but older rows still carry it.
  AUDIT_LOGS_VIEWED: "Viewed audit trail",
};

// Groups for the action filter, matched by code prefix in this order.
const ACTION_GROUPS: { label: string; prefixes: string[] }[] = [
  { label: "Sign-in and PIN", prefixes: ["AUTH_", "PIN_"] },
  { label: "Staff accounts", prefixes: ["USER"] },
  { label: "Brands", prefixes: ["BRAND_"] },
  { label: "Menu", prefixes: ["MENU_", "MODIFIER_"] },
  { label: "Orders", prefixes: ["ORDER_"] },
  { label: "Kitchen", prefixes: ["KITCHEN_"] },
  { label: "Images and audit trail", prefixes: ["ASSET_", "AUDIT_"] },
];

/** Every action the server records, grouped for the action filter. */
export const ACTION_OPTIONS: { label: string; actions: { code: string; label: string }[] }[] = ACTION_GROUPS.map(
  (group) => ({
    label: group.label,
    actions: Object.entries(ACTION_LABEL)
      .filter(([code]) => group.prefixes.some((prefix) => code.startsWith(prefix)))
      .map(([code, label]) => ({ code, label })),
  }),
);

const ENTITY_LABEL: Record<string, string> = {
  users: "Staff account",
  user_sessions: "Session",
  user_pin_credentials: "Action PIN",
  brands: "Brand",
  menu_items: "Menu item",
  menu_item_channels: "Menu item channel",
  menu_item_modifiers: "Menu item modifier",
  modifiers: "Modifier",
  recipes: "Recipe",
  orders: "Order",
  kitchen_tickets: "Kitchen ticket",
  kitchen_ticket_qc_attempts: "Quality check",
  assets: "Image",
  audit_logs: "Audit trail",
};

const REASON_TEXT: Record<string, string> = {
  ACCESS_DENIED: "Their role isn't allowed to do this.",
  RECIPE_ACCESS_DENIED: "Their role can't access this recipe.",
  UNAUTHORIZED_CHECKER: "They aren't the assigned checker for this ticket.",
  INVALID_CREDENTIALS: "Wrong username or password.",
  SESSION_TOKEN_REQUIRED: "The request had no signed-in session.",
  INVALID_SESSION: "The session had expired or was signed out.",
  EXPIRED_SESSION: "The session had expired.",
  INVALID_PIN: "Wrong action PIN.",
  PIN_LOCKED: "PIN entry was locked after too many wrong attempts.",
  PIN_NOT_CONFIGURED: "They haven't set up an action PIN yet.",
  EXISTING_PIN_FOUND: "An action PIN is already set up.",
  USERNAME_ALREADY_EXISTS: "That username is already taken.",
  KITCHEN_TICKET_INVALID_STATUS: "The ticket wasn't at a step that allows this.",
  KITCHEN_TICKET_PREPARER_ALREADY_ASSIGNED: "The ticket already has a preparer.",
  KITCHEN_TICKET_CHECKER_ALREADY_ASSIGNED: "The ticket already has a checker.",
  ORDER_INVALID_STATUS: "The order wasn't at a step that allows this.",
  ORDER_ID_CONFLICT: "That order was already recorded.",
  AVAILABILITY_CONFLICT: "Someone else changed availability first.",
  MENU_ITEM_CONFLICT: "Someone else changed this menu item first.",
  MENU_ITEM_LOCKED: "The menu item was being edited by someone else.",
  MENU_ITEM_ALREADY_ACTIVE: "The menu item was already active.",
  MENU_ITEM_CHANNEL_ALREADY_ACTIVE: "The channel price was already active.",
  MENU_ITEM_MODIFIER_ALREADY_ACTIVE: "The menu item modifier was already active.",
  MODIFIER_ALREADY_ACTIVE: "The modifier was already active.",
  INTERNAL_ERROR: "The server hit an unexpected error.",
};

function reasonText(code: string) {
  const http = /^HTTP_(\d{3})$/.exec(code);
  return REASON_TEXT[code] ?? (http ? `The request was rejected (HTTP ${http[1]}).` : humanize(code));
}

const FIELD_LABEL: Record<string, string> = {
  first_name: "First name",
  last_name: "Last name",
  is_active: "Status",
  is_available: "Availability",
  base_price: "Base price",
  img_url: "Image",
  logo_url: "Logo",
  order_code: "Order code",
  order_channel: "Channel",
  payment_method: "Payment method",
  payment_status: "Payment status",
  menu_item_id: "Menu item ID",
};

// Columns whose values are identifiers, so they are shown verbatim, never humanized.
const VERBATIM = new Set(["code", "order_code", "username", "menu_item_id", "img_url", "logo_url"]);

const peso = new Intl.NumberFormat("en-PH", { style: "currency", currency: "PHP" });

function formatValue(field: string, value: unknown): string | null {
  if (value === null || value === undefined || value === "") return null;
  if (field === "role" && typeof value === "string") return ROLE_LABEL[value as UserRole] ?? humanize(value);
  if (field === "is_active") return value ? "Active" : "Inactive";
  if (field === "is_available") return value ? "Available" : "Unavailable";
  if (typeof value === "boolean") return value ? "Yes" : "No";
  if ((field === "price" || field.endsWith("_price")) && !Number.isNaN(Number(value))) return peso.format(Number(value));
  if (typeof value === "string") return !VERBATIM.has(field) && /^[A-Z0-9_]+$/.test(value) ? humanize(value) : value;
  if (typeof value === "number") return String(value);
  return JSON.stringify(value);
}

function toChanges(before: AuditSnapshot | null, after: AuditSnapshot | null): Pick<AuditEntry, "changeKind" | "changes"> {
  if (!before && !after) return { changeKind: null, changes: [] };
  const fields = [...new Set([...Object.keys(before ?? {}), ...Object.keys(after ?? {})])];
  const changes = fields
    .filter((field) => !before || JSON.stringify(before[field]) !== JSON.stringify(after?.[field]))
    .map((field) => ({
      field,
      label: FIELD_LABEL[field] ?? humanize(field),
      before: before ? formatValue(field, before[field]) : null,
      after: after ? formatValue(field, after[field]) : null,
    }));
  return { changeKind: before ? "updated" : "created", changes };
}

export function toAuditEntry(log: AuditLog): AuditEntry {
  const { actor } = log;
  return {
    id: log.audit_log_id,
    time: log.created_at,
    actor:
      actor && log.actor_id
        ? {
            id: log.actor_id,
            name: `${actor.first_name} ${actor.last_name}`,
            username: actor.username,
            role: ROLE_LABEL[actor.role],
          }
        : null,
    action: ACTION_LABEL[log.action] ?? humanize(log.action),
    actionCode: log.action,
    entity: ENTITY_LABEL[log.entity_type] ?? humanize(log.entity_type),
    entityType: log.entity_type,
    entityId: log.entity_id,
    outcome: OUTCOME[log.outcome],
    reason: log.reason ? { code: log.reason, text: reasonText(log.reason) } : null,
    ...toChanges(log.before_data, log.after_data),
    requestId: log.request_id,
  };
}

// Pinned to Manila so server and client render the same string (no hydration mismatch).
const TIME_FORMAT = new Intl.DateTimeFormat("en-PH", {
  timeZone: "Asia/Manila",
  month: "short",
  day: "numeric",
  year: "numeric",
  hour: "numeric",
  minute: "2-digit",
});

const FULL_TIME_FORMAT = new Intl.DateTimeFormat("en-PH", {
  timeZone: "Asia/Manila",
  weekday: "short",
  month: "short",
  day: "numeric",
  year: "numeric",
  hour: "numeric",
  minute: "2-digit",
  second: "2-digit",
});

export function formatAuditTime(iso: string) {
  return TIME_FORMAT.format(new Date(iso));
}

/** Down to the second, for the detail view. */
export function formatAuditTimeFull(iso: string) {
  return FULL_TIME_FORMAT.format(new Date(iso));
}

// en-CA formats as YYYY-MM-DD, the value format of <input type="date">.
const DATE_VALUE_FORMAT = new Intl.DateTimeFormat("en-CA", {
  timeZone: "Asia/Manila",
  year: "numeric",
  month: "2-digit",
  day: "2-digit",
});

/** Today's Asia/Manila date as YYYY-MM-DD, the latest date worth filtering to. */
export function todayInManila() {
  return DATE_VALUE_FORMAT.format(new Date());
}
