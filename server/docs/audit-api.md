# Audit logs API

`GET /api/audit-logs` lists read-only audit records. Send
`Authorization: Bearer <session-token>` for a `SUPERADMIN` (owner) session.
There is no request body or PIN requirement. Other roles receive `403`.
Swagger request and response schemas are under **Audit logs** at `/api/docs`.

| Query parameter | Required | Type and constraints |
| --- | --- | --- |
| `page` | No | Integer, 1?2147483647; default 1 |
| `limit` | No | Integer, 1?100; default 10 |
| `action` | No | Exact, case-sensitive string, 1?100 characters with at least one non-whitespace character |
| `outcome` | No | `SUCCESS`, `DENIED`, or `FAILED` |

Filters combine with AND. Action values are not trimmed. The calculated offset
`(page - 1) * limit` must fit a signed 32-bit integer. Unknown query parameters
are rejected. Records sort by `created_at` descending, then `audit_log_id`
ascending for ties.

Example request:

```http
GET /api/audit-logs?page=1&limit=10&action=ORDER_CONFIRMED&outcome=SUCCESS
Authorization: Bearer <session-token>
```

Example `200` response (illustrative audit record):

```json
{
  "data": [{
    "audit_log_id": "11111111-1111-4111-8111-111111111111",
    "actor_id": null,
    "action": "ORDER_CONFIRMED",
    "entity_type": "orders",
    "entity_id": "22222222-2222-4222-8222-222222222222",
    "outcome": "SUCCESS",
    "reason": null,
    "before_data": { "status": "DRAFT", "payment_method": null },
    "after_data": { "status": "CONFIRMED", "payment_method": "CASH" },
    "request_id": "6f1c2d4e-8a9b-4c3d-9e2f-1a2b3c4d5e6f",
    "created_at": "2026-10-29T02:00:00.000Z"
  }],
  "meta": { "page": 1, "limit": 10, "total": 1, "totalPages": 1 }
}
```

| Response field | Type / meaning |
| --- | --- |
| `data` | Array of audit records; empty when no records match the page |
| `data[].audit_log_id` | UUID string |
| `data[].actor_id`, `data[].entity_id` | UUID string or null; full actor/user records are not included |
| `data[].action`, `data[].entity_type` | Strings identifying the action and entity type |
| `data[].outcome` | `SUCCESS`, `DENIED`, or `FAILED` |
| `data[].reason`, `data[].request_id` | String or null |
| `data[].before_data`, `data[].after_data` | JSON object or null; see [Snapshots](#snapshots) |
| `data[].created_at` | ISO 8601 timestamp |
| `meta.page`, `meta.limit` | Effective page and limit integers |
| `meta.total` | Number of records matching the filters across all pages |
| `meta.totalPages` | `ceil(total / limit)`; zero when no records match |

An empty result is `200` with `data: []`; requesting a page beyond the last page
also returns an empty array while preserving the matching total.

| Status | Cause |
| --- | --- |
| `400` | Invalid/unknown query parameters or offset out of range |
| `401` | Missing, invalid or expired session |
| `403` | Authenticated caller is not a superadmin |

Validation and business errors use Nest's error object, for example
`{ "statusCode": 400, "message": ["Limit must be at most 100."], "error": "Bad Request" }`.
`message` may be a string for non-validation errors. Audit records cannot be
created, edited, or deleted through this endpoint.

Authentication errors return `{ "code": "SESSION_TOKEN_REQUIRED", "message": "A bearer session token is required." }` or
`{ "code": "INVALID_SESSION", "message": "Invalid or expired session." }`.

## What gets audited

Audit rows are written automatically for routes marked with `@Audit()`
(`src/shared/audit/audit.decorator.ts`): every action endpoint (POST, PUT,
PATCH, DELETE) and a short list of sensitive reads. Routine reads such as
orders, kitchen tickets, menus and the kitchen ticket stream are not audited.
A route that changes nothing but uses POST (for example order verification)
opts out explicitly with `@NoAudit(reason)`.

| Outcome | Written when |
| --- | --- |
| `SUCCESS` | The handler completed. Written after its transaction commits, before the response is sent. |
| `DENIED` | The request was rejected with `401`, `403` or `429` (PIN lockout), including rejections by the authentication, role, PIN and recipe-access guards, which happen before any service code runs. |
| `FAILED` | The handler threw a `409` conflict or a `5xx` error. |

`400` validation errors and `404` not-found errors are not audited.

Each row stores:

- `actor_id`: the session user, or null when there is no session (for example
  a rejected login).
- `action`: `<ENTITY>_<PAST_VERB>`, for example `ORDER_CONFIRMED`.
- `entity_type`: the database table name, for example `orders`.
- `entity_id`: the affected record's UUID from the route or the response,
  otherwise null.
- `reason`: null on success. On failure it is the error's `code` (for
  example `KITCHEN_TICKET_INVALID_STATUS`), or `HTTP_<status>` /
  `INTERNAL_ERROR` when no well-formed code exists. Error messages are never
  stored.
- `request_id`: the request's `x-request-id`. Clients may send one (1–128
  characters of `A-Z a-z 0-9 . _ : -`); otherwise the server generates a UUID.
  Every response echoes it in the `x-request-id` header, so a client error
  report can be matched to its audit row.
- `before_data` / `after_data`: allowlisted column values for creations and
  state changes; see [Snapshots](#snapshots).

Request bodies, credentials, PINs and recipe contents are never written. If the
audit table cannot be written, the request still succeeds or fails exactly as it
would have, and a constant error message is logged.

A unit test (`src/shared/audit/tests/audit-coverage.spec.ts`) fails if any
action route lacks `@Audit()` or `@NoAudit()`, or if a listed sensitive read is
not audited.

### Snapshots

Routes declare `snapshot: 'create'` or `snapshot: 'update'` in `@Audit()`:

| Kind | `before_data` | `after_data` | Actions |
| --- | --- | --- | --- |
| Creation | null | the new record's allowlisted columns | `USER_CREATED`, `BRAND_CREATED`, `ORDER_CREATED`, `MENU_CATALOG_ENTRY_CREATED` and every menu `*_CREATED` |
| State change | the **changed** columns' old values | the same columns' new values | field edits (`*_UPDATED`), `*_DEACTIVATED` / `*_REACTIVATED`, `MENU_ITEM_AVAILABILITY_CHANGED`, `ORDER_CONFIRMED`, `ORDER_CANCELLED`, every `KITCHEN_TICKET_*` step and claim, `KITCHEN_QC_PASSED` / `KITCHEN_QC_REJECTED` |

For example, a price edit stores `before_data: { "base_price": "150" }` and
`after_data: { "base_price": "165" }`. An update that changes no allowlisted
column stores null in both. `DENIED` and `FAILED` rows never store snapshots.

Values are read from the database, never from request or response bodies: once
before the handler runs (state changes) and once after it succeeds. Each read
selects only the allowlisted columns below, so nothing else can be stored.
Decimals are stored as strings and timestamps as ISO 8601 strings. If a read
fails, the row is still written with that snapshot null. The "before" read
happens just before the handler's transaction, so a concurrent edit can make it
slightly stale.

| Entity | Allowlisted columns |
| --- | --- |
| `users` | `username`, `first_name`, `last_name`, `role`, `is_active` |
| `brands` | `code`, `name`, `logo_url`, `is_active` |
| `orders` | `order_code`, `order_channel`, `status`, `payment_method`, `payment_status`, `table_reference`, `merchant_store_reference`, `external_order_reference` |
| `menu_items` | `code`, `name`, `description`, `serving_description`, `base_price`, `img_url`, `is_available`, `is_active` |
| `menu_item_channels` | `menu_item_id`, `order_channel`, `price`, `is_available` |
| `modifiers` | `code`, `name`, `description`, `is_active` |
| `menu_item_modifiers` | `menu_item_id`, `modifier_id`, `additional_price`, `is_available` |
| `kitchen_tickets` | `status`, `preparer_id`, `checker_id` |
| `kitchen_ticket_qc_attempts` | `attempt_number`, `status`, `checker_id` |

The allowlists live in `src/shared/audit/audit-snapshots.ts`. These columns
are never snapshotted, and the server refuses to start if an allowlist includes
one: `password_hash`, `pin_hash`, `token_hash`, `create_request_hash`,
`recipe_id`, `recipe_snapshot`, `payment_reference`, and the free-text
`notes` and `cancellation_reason`, which can contain customer details (they
remain on the order itself). Login, logout, PIN, asset and audit-view actions
have no snapshots.

A QC pass also moves its kitchen ticket to `READY`, but the row's entity is the
QC attempt, so only the attempt's status change is captured there.

### Action catalog

Actions are added module by module as auditing is rolled out.

| Action | Entity | Endpoint |
| --- | --- | --- |
| `AUTH_LOGIN` | `users` | `POST /api/auth/login`. Actor and entity are the logged-in user. A wrong username or password is `DENIED` (`INVALID_CREDENTIALS`) with a null actor; usernames are not stored. |
| `AUTH_LOGOUT` | `user_sessions` | `POST /api/auth/logout`. Entity is the ended session. |
| `AUTH_LOGOUT_ALL` | `users` | `POST /api/auth/logout-all`. Entity is the user whose sessions were ended. |
| `USER_CREATED` | `users` | `POST /api/users`. Entity is the new user. PIN failures are `DENIED` (`INVALID_PIN`, `PIN_NOT_CONFIGURED`, `PIN_LOCKED`). |
| `USER_UPDATED` | `users` | `PATCH /api/users/:id`. |
| `USER_DEACTIVATED` | `users` | `DELETE /api/users/:id` (deactivates the account). |
| `USERS_LISTED` | `users` | `GET /api/users` (sensitive read; entity is null). |
| `USER_VIEWED` | `users` | `GET /api/users/:id`. Entity is the viewed user, also when looked up by username. |
| `PIN_CREATED` | `user_pin_credentials` | `POST /api/pin`. Entity is the PIN owner (the actor). An existing PIN is `FAILED` (`EXISTING_PIN_FOUND`). |
| `PIN_UPDATED` | `user_pin_credentials` | `PATCH /api/pin`. A wrong current password is `DENIED` (`INVALID_CREDENTIALS`). PINs and passwords are never stored. |
| `BRAND_CREATED` | `brands` | `POST /api/brands`. Entity is the new brand. A duplicate code is `FAILED` (`DUPLICATE_RESOURCE`). |
| `BRAND_UPDATED` | `brands` | `PATCH /api/brands/:brandId`. |
| `BRAND_DEACTIVATED` | `brands` | `DELETE /api/brands/:brandId` (soft delete: sets `is_active` to false). |
| `ORDER_CREATED` | `orders` | `POST /api/brands/:brandId/orders`. Entity is the new order. An idempotent retry of the same request returns the existing order and writes another `SUCCESS` row for it. A duplicate platform order is `FAILED` (`DUPLICATE_PLATFORM_ORDER`). |
| `ORDER_CONFIRMED` | `orders` | `POST /api/brands/:brandId/orders/:orderId/confirm`. Confirming also creates the order's kitchen ticket; kitchen actions are audited separately. |
| `ORDER_CANCELLED` | `orders` | `POST /api/brands/:brandId/orders/:orderId/cancel` (draft orders). Cancelling an already cancelled draft also succeeds and writes another `SUCCESS` row. |

`POST /api/brands/:brandId/orders/:orderId/verify` is not audited: it only checks prices and availability and writes nothing.

Kitchen actions:

| Action | Entity | Endpoint |
| --- | --- | --- |
| `KITCHEN_TICKET_PREPARER_ASSIGNED` | `kitchen_tickets` | `PATCH /api/kitchen-ticket/:id/preparer`. A ticket that already has a preparer is `FAILED` (`KITCHEN_TICKET_PREPARER_ALREADY_ASSIGNED`). |
| `KITCHEN_TICKET_CHECKER_ASSIGNED` | `kitchen_tickets` | `PATCH /api/kitchen-ticket/:id/checker`. |
| `KITCHEN_TICKET_ACKNOWLEDGED` | `kitchen_tickets` | `POST /api/kitchen-fulfillment/:kitchenTicketId/acknowledge`. |
| `KITCHEN_TICKET_PREPARATION_STARTED` | `kitchen_tickets` | `POST /api/kitchen-fulfillment/:kitchenTicketId/prepare`. |
| `KITCHEN_TICKET_SENT_FOR_CHECKING` | `kitchen_tickets` | `POST /api/kitchen-fulfillment/:kitchenTicketId/for-checking`. |
| `KITCHEN_TICKET_CHECK_STARTED` | `kitchen_tickets` | `POST /api/kitchen-fulfillment/:kitchenTicketId/check` (opens a QC attempt). |
| `KITCHEN_QC_PASSED` | `kitchen_ticket_qc_attempts` | `POST /api/kitchen-fulfillment/qc-attempts/:attemptId/pass`. Entity is the QC attempt. |
| `KITCHEN_QC_REJECTED` | `kitchen_ticket_qc_attempts` | `POST /api/kitchen-fulfillment/qc-attempts/:attemptId/reject`. Entity is the QC attempt; rejection details are not stored in the audit row. |
| `KITCHEN_TICKET_HANDED_OVER` | `kitchen_tickets` | `POST /api/kitchen-fulfillment/:kitchenTicketId/hand-over`. |
| `ORDER_CANCELLED` | `orders` | `POST /api/kitchen-fulfillment/brands/:brandId/orders/:orderId/cancel` (confirmed orders; also cancels the kitchen ticket). Uses the same action as the draft cancel, so `action=ORDER_CANCELLED` lists every cancellation. |

Status conflicts are `FAILED` (for example `KITCHEN_TICKET_INVALID_STATUS`), and acting on a ticket assigned to someone else is `DENIED` (for example `KITCHEN_TICKET_PREPARER_MISMATCH`). Kitchen ticket and QC reads, including the ticket stream, are not audited.

Menu actions:

| Action | Entity | Endpoint |
| --- | --- | --- |
| `MENU_CATALOG_ENTRY_CREATED` | `menu_items` | `POST /api/menu-catalog`. Entity is the new menu item. |
| `MENU_ITEM_CREATED` | `menu_items` | `POST /api/menu-items`. Entity is the new record. |
| `MENU_ITEM_UPDATED` | `menu_items` | `PATCH /api/menu-items/:id`. |
| `MENU_ITEM_REACTIVATED` | `menu_items` | `PATCH /api/menu-items/reactivate/:id`. |
| `MENU_ITEM_DEACTIVATED` | `menu_items` | `DELETE /api/menu-items/:id` (soft delete). |
| `MENU_ITEM_AVAILABILITY_CHANGED` | `menu_items` | `PATCH /api/menu-items/availability/:id`. Kitchen and inventory staff may use it, so the row records who marked an item sold out. |
| `MENU_ITEM_CHANNEL_CREATED` | `menu_item_channels` | `POST /api/menu-channels`. Entity is the new record. |
| `MENU_ITEM_CHANNEL_UPDATED` | `menu_item_channels` | `PATCH /api/menu-channels/:id`. |
| `MENU_ITEM_CHANNEL_REACTIVATED` | `menu_item_channels` | `PATCH /api/menu-channels/reactivate/:id`. |
| `MENU_ITEM_CHANNEL_DEACTIVATED` | `menu_item_channels` | `DELETE /api/menu-channels/:id` (soft delete). |
| `MODIFIER_CREATED` | `modifiers` | `POST /api/modifiers`. Entity is the new record. |
| `MODIFIER_UPDATED` | `modifiers` | `PATCH /api/modifiers/:id`. |
| `MODIFIER_REACTIVATED` | `modifiers` | `PATCH /api/modifiers/reactivate/:id`. |
| `MODIFIER_DEACTIVATED` | `modifiers` | `DELETE /api/modifiers/:id` (soft delete). |
| `MENU_ITEM_MODIFIER_CREATED` | `menu_item_modifiers` | `POST /api/menu-item-modifiers`. Entity is the new record. |
| `MENU_ITEM_MODIFIER_UPDATED` | `menu_item_modifiers` | `PATCH /api/menu-item-modifiers/:id`. |
| `MENU_ITEM_MODIFIER_REACTIVATED` | `menu_item_modifiers` | `PATCH /api/menu-item-modifiers/reactivate/:id`. |
| `MENU_ITEM_MODIFIER_DEACTIVATED` | `menu_item_modifiers` | `DELETE /api/menu-item-modifiers/:id` (soft delete). |

A duplicate code is `FAILED` (`DUPLICATE_RESOURCE`). Deactivating an already inactive record is a `404` and is not audited. Menu reads are not audited.

Asset actions:

| Action | Entity | Endpoint |
| --- | --- | --- |
| `ASSET_UPLOADED` | `assets` | `POST /api/assets`. |
| `ASSET_DOWNLOAD_URL_ISSUED` | `assets` | `GET /api/assets/download-url` (sensitive read). |

Assets are S3 objects identified by their key rather than a database row, so
`entity_type` is `assets` and `entity_id` is null; the key and signed URL are
not stored. A storage outage is `FAILED` (`HTTP_503`). Rejected files (empty,
over 5 MiB, wrong type) and unknown keys are not audited. Images uploaded as
part of another action (brand logos, menu item images, hand-over photos) are
covered by that action's row.

Audit trail access:

| Action | Entity | Endpoint |
| --- | --- | --- |
| `AUDIT_LOGS_VIEWED` | `audit_logs` | `GET /api/audit-logs` (sensitive read). Non-superadmins are `DENIED` (`ACCESS_DENIED`). The row is written after the query runs, so a view does not appear in its own results. |

Not yet audited: `PATCH /api/recipes/:id` and the sensitive read
`GET /api/recipes/:id`. Recipe access **denials** are still recorded by the
recipe access check as `RECIPE_<action>` rows with outcome `DENIED`.
