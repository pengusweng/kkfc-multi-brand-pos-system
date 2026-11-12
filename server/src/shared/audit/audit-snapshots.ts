import { Prisma } from '@prisma/client';

/** A JSON-safe snapshot of allowlisted columns. */
export type AuditSnapshot = Record<string, Prisma.JsonValue>;

export type SnapshotMode = 'create' | 'update';

type SnapshotModel =
  | 'user'
  | 'brand'
  | 'order'
  | 'menuItem'
  | 'menuItemChannel'
  | 'modifier'
  | 'menuItemModifier'
  | 'kitchenTicket'
  | 'kitchenTicketQcAttempt';

export interface SnapshotConfig {
  /** Prisma client delegate, e.g. `menuItem`. */
  model: SnapshotModel;
  /** Primary-key column the audit row's entity_id refers to. */
  key: string;
  /** The only columns ever read into before_data / after_data. */
  fields: readonly string[];
}

/**
 * The single allowlist of columns that may appear in audit snapshots, keyed by
 * audit entity (table name). Snapshots are read from the database with a
 * `select` of exactly these fields, never from request or response bodies, so
 * nothing outside this list can be stored.
 */
export const SNAPSHOT_CONFIGS: Readonly<Record<string, SnapshotConfig>> = {
  users: {
    model: 'user',
    key: 'user_id',
    fields: ['username', 'first_name', 'last_name', 'role', 'is_active'],
  },
  brands: {
    model: 'brand',
    key: 'brand_id',
    fields: ['code', 'name', 'logo_url', 'is_active'],
  },
  orders: {
    model: 'order',
    key: 'order_id',
    fields: [
      'order_code',
      'order_channel',
      'status',
      'payment_method',
      'payment_status',
      'table_reference',
      'merchant_store_reference',
      'external_order_reference',
    ],
  },
  menu_items: {
    model: 'menuItem',
    key: 'menu_item_id',
    fields: [
      'code',
      'name',
      'description',
      'serving_description',
      'base_price',
      'img_url',
      'is_available',
      'is_active',
    ],
  },
  menu_item_channels: {
    model: 'menuItemChannel',
    key: 'menu_item_channel_id',
    fields: ['menu_item_id', 'order_channel', 'price', 'is_available'],
  },
  modifiers: {
    model: 'modifier',
    key: 'modifier_id',
    fields: ['code', 'name', 'description', 'is_active'],
  },
  menu_item_modifiers: {
    model: 'menuItemModifier',
    key: 'menu_item_modifier_id',
    fields: ['menu_item_id', 'modifier_id', 'additional_price', 'is_available'],
  },
  kitchen_tickets: {
    model: 'kitchenTicket',
    key: 'kitchen_ticket_id',
    fields: ['status', 'preparer_id', 'checker_id'],
  },
  kitchen_ticket_qc_attempts: {
    model: 'kitchenTicketQcAttempt',
    key: 'qc_attempt_id',
    fields: ['attempt_number', 'status', 'checker_id'],
  },
};

/**
 * Columns that must never be snapshotted: credentials, request hashes,
 * confidential recipe links, payment references and free text that may hold
 * customer details.
 */
export const FORBIDDEN_SNAPSHOT_FIELDS: readonly string[] = [
  'password_hash',
  'pin_hash',
  'token_hash',
  'create_request_hash',
  'recipe_id',
  'recipe_snapshot',
  'payment_reference',
  'notes',
  'cancellation_reason',
];

// Fail at startup, not in production data, if an allowlist is ever widened
// to include a forbidden column.
for (const [entity, config] of Object.entries(SNAPSHOT_CONFIGS)) {
  const leaked = config.fields.filter((field) =>
    FORBIDDEN_SNAPSHOT_FIELDS.includes(field),
  );
  if (leaked.length > 0) {
    throw new Error(
      `Audit snapshot for ${entity} includes forbidden fields: ${leaked.join(', ')}`,
    );
  }
}

/** Converts a selected row into JSON: Decimal → string, Date → ISO string. */
export function toSnapshotJson(row: Record<string, unknown>): AuditSnapshot {
  return Object.fromEntries(
    Object.entries(row).map(([key, value]): [string, Prisma.JsonValue] => {
      if (Prisma.Decimal.isDecimal(value)) return [key, value.toString()];
      if (value instanceof Date) return [key, value.toISOString()];
      // Remaining allowlisted columns are strings, numbers, booleans or enums.
      return [key, value ?? null];
    }),
  );
}

/**
 * Keeps only the fields that changed between two snapshots. When either side
 * is missing, both are returned as is; when nothing changed, both are null.
 */
export function changedFields(
  before: AuditSnapshot | null,
  after: AuditSnapshot | null,
): { before: AuditSnapshot | null; after: AuditSnapshot | null } {
  if (!before || !after) return { before, after };

  const keys = [
    ...new Set([...Object.keys(before), ...Object.keys(after)]),
  ].filter(
    (key) =>
      JSON.stringify(before[key] ?? null) !==
      JSON.stringify(after[key] ?? null),
  );
  if (keys.length === 0) return { before: null, after: null };

  const pick = (snapshot: AuditSnapshot) =>
    Object.fromEntries(keys.map((key) => [key, snapshot[key] ?? null]));
  return { before: pick(before), after: pick(after) };
}
