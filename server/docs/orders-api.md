# Order API

All routes use `/api/brands/:brandId/orders` and a bearer session.
Allowed roles: CASHIER_STAFF, MANAGER, SUPERADMIN, across all brands.
Orders remain scoped to the URL brand. Missing orders or wrong-brand order URLs return 404.
Creation rejects unavailable brands with 400.

## Requests and responses

Interactive schemas are available under **Orders** at `/api/docs` (OpenAPI JSON:
`/api/docs-json`). Send `Authorization: Bearer <session-token>` and
`Content-Type: application/json`. No PIN is required. Path parameters `brandId`
and `orderId` must be UUIDs. Unknown body and query properties are rejected.

| Endpoint (relative to `/api/brands/:brandId/orders`) | Required input                                                          | Success                                         |
| ---------------------------------------------------- | ----------------------------------------------------------------------- | ----------------------------------------------- |
| `GET /`                                              | Optional `page`, `limit`, `status`, `order_channel`, `order_date` query | `200`, `{ orders, total }`                      |
| `GET /:orderId`                                      | None                                                                    | `200`, saved order                              |
| `POST /`                                             | `order_id`, `order_channel`, `lines`; channel-specific references below | `201`, saved order, including identical replays |
| `POST /:orderId/verify`                              | Payment body below; existing draft order                                | `200`, validation result with current lines     |
| `POST /:orderId/confirm`                             | Payment body below; existing order                                      | `200`, saved order with kitchen ticket          |
| `POST /:orderId/cancel`                              | `cancellation_reason`; draft without a kitchen ticket                    | `200`, saved cancelled draft                    |

### List and get orders

`GET /api/brands/:brandId/orders` returns a page of the brand's orders in every
status (drafts, confirmed, cancelled and completed). It never returns another
brand's orders. Results are sorted by `created_at` descending, then `order_id`
ascending, so pages are stable.

| Query parameter | Required | Type and constraints                                                                   |
| --------------- | -------- | -------------------------------------------------------------------------------------- |
| `page`          | No       | Integer, 1 or more; default `1`. The calculated offset must fit a signed 32-bit integer |
| `limit`         | No       | Integer, 1-100; default `10`                                                           |
| `status`        | No       | `DRAFT`, `CONFIRMED`, `PREPARING`, `COMPLETED`, or `CANCELLED`                         |
| `order_channel` | No       | `DINE_IN`, `TAKEAWAY`, `GRABFOOD`, `FOODPANDA`                                         |
| `order_date`    | No       | `YYYY-MM-DD` Asia/Manila business date, the same date used for daily order numbers     |

Filters are combined with AND. Example request:

```http
GET /api/brands/44444444-4444-4444-8444-444444444444/orders?status=CONFIRMED&order_date=2026-10-29&page=1&limit=20
Authorization: Bearer <session-token>
```

Example `200` response, with the saved order object abbreviated here:

```json
{
  "orders": [
    {
      "order_id": "11111111-1111-4111-8111-111111111111",
      "order_code": "GC-00001",
      "status": "CONFIRMED",
      "order_items_order": [],
      "kitchen_tickets_order": { "ticket_number": "T-001", "status": "QUEUED" }
    }
  ],
  "total": 1
}
```

Each element of `orders` is the full saved order response described below. `total`
is the number of orders matching the filters across all pages. When nothing
matches, the response is `{ "orders": [], "total": 0 }`; an unknown brand also
returns an empty page rather than 404. A page beyond the supported offset range
returns `400 PAGINATION_UNSUPPORTED_RANGE`.

`GET /api/brands/:brandId/orders/:orderId` returns one saved order in any status.
A missing order, or one belonging to a different brand, returns `404`.

Both retrieval endpoints are read-only. They use the same redaction as the other
order responses: `create_request_hash` and item `recipe_snapshot` are never
returned.

### Create body

| Field                      | Required              | Type and constraints                                                                      |
| -------------------------- | --------------------- | ----------------------------------------------------------------------------------------- |
| `order_id`                 | Yes                   | Client-generated UUID; reuse unchanged on retries                                         |
| `order_channel`            | Yes                   | `DINE_IN`, `TAKEAWAY`, `GRABFOOD`, `FOODPANDA`                                            |
| `lines`                    | Yes                   | Array of 1-100 lines                                                                      |
| `lines[].menu_item_id`     | Yes                   | UUID of an available menu item in this brand/channel, with an active menu assembly recipe |
| `lines[].quantity`         | Yes                   | Integer, 1-9999                                                                           |
| `lines[].modifier_ids`     | No                    | Up to 100 unique UUIDs; modifiers must be active and available for the item               |
| `lines[].notes`, `notes`   | No                    | String, maximum 2000 characters                                                           |
| `table_reference`          | For `DINE_IN`         | Nonblank trimmed string, maximum 50 characters                                            |
| `merchant_store_reference` | For platform channels | Nonblank trimmed string, maximum 255 characters; not allowed for internal orders          |
| `external_order_reference` | For platform channels | Nonblank trimmed string, maximum 255 characters; not allowed for internal orders          |

Example `POST /api/brands/:brandId/orders` body (replace UUIDs with your records):

```json
{
  "order_id": "11111111-1111-4111-8111-111111111111",
  "order_channel": "TAKEAWAY",
  "lines": [
    {
      "menu_item_id": "22222222-2222-4222-8222-222222222222",
      "quantity": 2
    }
  ]
}
```

The `201` body is the saved order object described below. A fresh internal draft
has `status: "DRAFT"`, `payment_method: null`, `payment_status: "UNPAID"`,
`confirmed_at: null`, `applied_recipe_id: null` on each item, and
`kitchen_tickets_order: null`. A replay returns the order's current saved state.

### Verify and confirm bodies

| Field               | Required                 | Type and constraints                                                                           |
| ------------------- | ------------------------ | ---------------------------------------------------------------------------------------------- |
| `payment_method`    | For `DINE_IN`/`TAKEAWAY` | `CASH`, `E_WALLET`, or `CARD`; platform channels default to and only accept `PLATFORM_SETTLED` |
| `payment_status`    | For `DINE_IN`/`TAKEAWAY` | `UNPAID` or `PAID`; platform channels default to and only accept `PAID`                        |
| `payment_reference` | No                       | String, maximum 255 characters; defaults to null                                               |

Example body for both internal-order endpoints:

```json
{ "payment_method": "CASH", "payment_status": "PAID" }
```

Platform orders may send `{}`. Verification does not persist payment or prices.
Confirmation saves them; later confirmations return the first saved result.

Example `200` verification response:

```json
{
  "order_id": "11111111-1111-4111-8111-111111111111",
  "valid": true,
  "payment_method": "CASH",
  "payment_status": "PAID",
  "payment_reference": null,
  "lines": [
    {
      "menu_item_id": "22222222-2222-4222-8222-222222222222",
      "item_name": "Chicken meal",
      "quantity": 2,
      "unit_price": "125.5",
      "notes": null,
      "applied_recipe_id": "33333333-3333-4333-8333-333333333333",
      "modifiers": []
    }
  ]
}
```

Each verification modifier contains `modifier_id`, `modifier_name`, and
`additional_price`. Validation failures return an error, not `valid: false`.

### Cancel body and response

`POST /api/brands/:brandId/orders/:orderId/cancel` uses the same bearer session,
allowed roles as the other order endpoints. No PIN is required.

| Body field            | Required | Constraints                                                           |
| --------------------- | -------- | --------------------------------------------------------------------- |
| `cancellation_reason` | Yes      | String containing a non-whitespace character; maximum 1000 characters |

Example request (replace the path UUIDs and session token):

```http
POST /api/brands/44444444-4444-4444-8444-444444444444/orders/11111111-1111-4111-8111-111111111111/cancel
Authorization: Bearer <session-token>
Content-Type: application/json

{ "cancellation_reason": "Customer requested cancellation." }
```

`cancellation_reason` is required: a nonblank string of at most 1000 characters.
Surrounding whitespace is removed before saving. Unknown fields are rejected;
the cancellation actor comes from the authenticated session.

Returns `200` with the saved order response below, setting `status` to
`CANCELLED`, `cancelled_by_id` to the session user UUID, `cancellation_reason`
to the trimmed reason, and `cancelled_at`/`modified_at` to the cancellation time.
Only drafts without a kitchen ticket can use this endpoint. Their ticket remains
null. Orders with kitchen tickets use the kitchen fulfillment endpoint below.

Example `200 OK` response for cancellation of an unpaid draft:

```json
{
  "order_id": "11111111-1111-4111-8111-111111111111",
  "order_code": "GC-00001",
  "order_date": "2026-10-29T00:00:00.000Z",
  "order_number": 1,
  "brand_id": "44444444-4444-4444-8444-444444444444",
  "created_by_id": "55555555-5555-4555-8555-555555555555",
  "order_channel": "TAKEAWAY",
  "merchant_store_reference": null,
  "external_order_reference": null,
  "table_reference": null,
  "status": "CANCELLED",
  "payment_method": null,
  "payment_status": "UNPAID",
  "payment_reference": null,
  "notes": null,
  "cancelled_by_id": "55555555-5555-4555-8555-555555555555",
  "cancellation_reason": "Customer requested cancellation.",
  "cancelled_at": "2026-10-29T02:05:00.000Z",
  "confirmed_at": null,
  "completed_at": null,
  "created_at": "2026-10-29T02:00:00.000Z",
  "modified_at": "2026-10-29T02:05:00.000Z",
  "order_items_order": [
    {
      "order_item_id": "66666666-6666-4666-8666-666666666666",
      "order_id": "11111111-1111-4111-8111-111111111111",
      "menu_item_id": "22222222-2222-4222-8222-222222222222",
      "applied_recipe_id": null,
      "item_name": "Chicken meal",
      "quantity": 2,
      "unit_price": "125.5",
      "notes": null,
      "order_item_modifiers_order_item": []
    }
  ],
  "kitchen_tickets_order": null
}
```

`POST /api/kitchen-fulfillment/brands/:brandId/orders/:orderId/cancel` cancels an
order with a kitchen ticket. It accepts the same reason as draft cancellation,
requires a valid authenticated session with the SUPERADMIN, MANAGER, SUPERVISOR,
or KITCHEN_HEAD role, and returns `{ order, ticket }`. The fulfillment service calls the
kitchen-ticket and order services in one serializable transaction. Each record
keeps its own cancellation timestamp; the returned order includes the final ticket.

The orders endpoint returns `409 ORDER_NOT_DRAFT` for orders with tickets or
non-draft orders. The fulfillment endpoint returns `409 ORDER_HAS_NO_KITCHEN_TICKET`
for drafts, and rejects COMPLETED orders and HANDED_OVER tickets. Both endpoints
preserve the original cancellation details on retries. Every request, including
retries, must contain a valid reason.

Order identity, daily number, item snapshots and payment records are preserved.
This endpoint performs no refund, platform synchronization or inventory movement.

Cancellation error responses:

| Status | Cause                                                                                                              |
| ------ | ------------------------------------------------------------------------------------------------------------------ |
| `400`  | Missing, blank, non-string or overlong reason; unknown body fields; invalid path UUIDs |
| `401`  | Missing, invalid or expired bearer session                                                                         |
| `403`  | Caller lacks an allowed role |
| `404`  | Order not found within the requested brand |
| `409`  | Wrong cancellation endpoint for the order, completed order, handed-over ticket, or exhausted concurrency retries |

Example `409 Conflict` body from the draft orders endpoint:

```json
{
  "code": "ORDER_NOT_DRAFT",
  "message": "Only draft orders can be cancelled here. Cancel orders with a kitchen ticket through kitchen fulfillment."
}
```

### Saved order response (`201` create / `200` get, list, confirm or cancel)

Responses are direct objects, without a `data` wrapper. Decimal prices are JSON
strings; timestamps are ISO 8601 strings. Nullable fields are present as null.
The complete nested schemas are shown in Swagger.

| Fields                                                                             | JSON type / meaning                                                          |
| ---------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| `order_id`, `brand_id`, `created_by_id`                                            | UUID strings                                                                 |
| `order_code`, `order_date`, `order_number`                                         | Display code, Manila date as midnight UTC ISO string, integer daily sequence |
| `order_channel`, `status`                                                          | Channel and order status enums                                               |
| `merchant_store_reference`, `external_order_reference`, `table_reference`, `notes` | String or null                                                               |
| `payment_method`, `payment_status`, `payment_reference`                            | Method enum or null, status enum, string or null                             |
| `cancelled_by_id`, `cancellation_reason`                                           | UUID or null, string or null                                                 |
| `cancelled_at`, `confirmed_at`, `completed_at`                                     | ISO timestamp or null                                                        |
| `created_at`, `modified_at`                                                        | ISO timestamp                                                                |
| `order_items_order`                                                                | Array of saved items (below)                                                 |
| `kitchen_tickets_order`                                                            | Null before confirmation; saved ticket object after confirmation             |

Each saved item contains `order_item_id`, `order_id`, `menu_item_id`,
`applied_recipe_id` (nullable UUID), `item_name`, `quantity` (integer),
`unit_price` (decimal string), `notes` (nullable string), and
`order_item_modifiers_order_item` (array). Each saved modifier contains
`order_item_modifier_id`, `order_item_id`, `modifier_id`, `modifier_name`, and
`additional_price` (decimal string).

The ticket contains `kitchen_ticket_id`, `order_id`, `ticket_number`, `status`,
`created_by_id`, `created_at`, and `modified_at`. Its nullable fields are
`preparer_id`, `checker_id`, `acknowledged_at`, `preparation_started_at`,
`ready_at`, `handed_over_at`, `cancelled_at`, and `notes`.
A new confirmation sets order status to `CONFIRMED` and ticket status to `QUEUED`.
Neither `create_request_hash` nor `recipe_snapshot` is returned.

#### Order items on kitchen tickets

The kitchen ticket read endpoints (`GET /api/kitchen-ticket`, `/today`,
`/today/stream`, `/preparer/:preparerId`, `/checker/:checkerId` and `/:id`) include an
`order_items` array on each ticket so kitchen clients can identify items without
the Order API. Each element contains `order_item_id`, `menu_item_id`,
`item_name`, `quantity`, `notes`, and `modifiers` (each with
`order_item_modifier_id`, `modifier_id`, and `modifier_name`). Prices and recipe
snapshots are not included.

Use `order_items[].order_item_id` as `rejections[].order_item_id` in
`POST /api/kitchen-fulfillment/qc-attempts/:attemptId/reject`, with
`portion_number` between 1 and that item's `quantity`. Ticket state-change and
assignment responses still return the ticket without `order_items`.

#### Live kitchen tickets (SSE)

`GET /api/kitchen-ticket/today/stream` is a Server-Sent Events stream of the
same list `GET /api/kitchen-ticket/today` returns. It needs the same bearer
session and kitchen roles. Each message is unnamed (no `event:` line), carries
the whole list, and gets an incrementing `id` from Nest:

```text
id: 1
data: [{"kitchen_ticket_id":"…","status":"QUEUED","order_items":[…]}, …]

```

- The first message is sent as soon as the connection opens, so clients don't
  need a separate `GET /today` to load the initial list.
- A new message follows every committed ticket change: confirming an order
  (creates the ticket), assigning a preparer or checker, and each kitchen
  fulfillment step (acknowledge through hand-over or cancel).
- Each message replaces the previous list. Missed messages are not replayed;
  reconnecting sends the current list again.
- Every 15 seconds the server also sends an SSE comment line, `: ping`, so idle
  connections are not dropped by client timeouts or proxies. SSE clients ignore
  comments; hand-written parsers should skip lines starting with `:`.
- If loading the list fails, that update is skipped (and logged) and the stream
  stays open; the next change sends the current list.
- Because the endpoint needs an `Authorization` header, a browser
  `EventSource` cannot use it. Use a client that can set headers (Dio, curl,
  `fetch` with a stream reader). Disable client receive timeouts for this
  request, because the stream is silent while nothing changes.

Try it locally:

```bash
curl -N -H "Authorization: Bearer <session token>" \
  http://localhost:3000/api/kitchen-ticket/today/stream
```

Server side, `KitchenTicketChanges` (a shared rxjs subject) signals changes and
the stream refetches `findMany()` on each signal. Call
`KitchenTicketService.notifyChange()` (or `KitchenTicketChanges.notify()` from
outside the kitchen ticket module) only **after** the write's transaction has
committed, or subscribers will reload the pre-commit state. Status transition
methods that accept a `tx` do not notify; their callers do. The subject is
in-memory, so this only works with a single API instance.

Known limits: the session is only checked when the stream connects, so a
logged-out session keeps receiving updates until it disconnects; and "today"
is evaluated per refresh, so if nothing changes after midnight (Asia/Manila)
the last list stays on screen until the next change or reconnect.

### Errors

| Status | Cause                                                                                                                                                             |
| ------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `400`  | Invalid UUID/body/query, unknown fields, URL/order brand mismatch, missing channel references or payment inputs, unavailable menu/recipe/modifier, invalid catalog data, unsupported page range |
| `401`  | Missing, invalid or expired session                                                                                                                               |
| `403`  | Role access denied                                                                                                                                                |
| `404`  | Brand or order not found                                                                                                                                          |
| `409`  | Conflicting create replay, duplicate platform reference, invalid lifecycle/ticket state, or exhausted concurrency retries                                         |
| `503`  | Confirmation ticket sequence unavailable or invalid                                                                                                               |

Validation and business errors use Nest's error object, for example
`{ "statusCode": 400, "message": "Dine-in requires a table reference.", "error": "Bad Request" }`.
Validation errors may have a string array in `message`.

## Lifecycle and implementation notes

The controller handles HTTP input, the service owns lifecycle/payment/catalog
validation, cancellation and response redaction, and `OrdersRepository` owns database operations
and serializable transaction retries. Each lifecycle operation uses one transaction
for all reads and writes, including item snapshots, counters, and tickets.

The feature is organized into `modules/orders/orders/` (controller, lifecycle
service, repository, and order DTOs) and `modules/orders/order-items/` (line DTO,
item validation, catalog snapshots, and item persistence). `OrdersModule` imports
`OrderItemsModule`, which exports `OrderItemsService` and does not depend on orders.
Orders supplies its transaction when calling the item service. Draft creation
continues to insert the order and its nested items together through the orders
repository.

- `GET /`: list the brand's orders with pagination and optional status, channel
  and Manila order-date filters. The page and total are read together under
  repeatable-read isolation.
- `GET /:orderId`: fetch one order scoped to the URL brand.
- `POST /`: create a draft. Required body: client-generated `order_id` UUID,
  `order_channel`, and nonempty `lines` (`menu_item_id`, positive integer `quantity`,
  optional unique `modifier_ids` and `notes`). Optional order `notes`.
  Dine-in requires `table_reference`; platform channels require
  `merchant_store_reference` and `external_order_reference`.
- `POST /:orderId/verify`: validate a draft and return current prices, modifiers
  and recipe IDs without writes. This does not reserve prices or stock.
- `POST /:orderId/confirm`: atomically capture current prices, modifier names/prices
  and complete recipe contents, create a QUEUED ticket and set CONFIRMED.
- `POST /:orderId/cancel`: require `cancellation_reason` and cancel a draft without
  a kitchen ticket, recording actor and time. Returns the original cancellation
  details on retries. Orders with tickets use the kitchen fulfillment endpoint.

Verify/confirm accept `payment_method`, `payment_status` and optional
`payment_reference`. Dine-in/takeaway require CASH, E_WALLET or CARD plus UNPAID
or PAID. Platform orders use PLATFORM_SETTLED/PAID, including drafts; conflicting
payment inputs are rejected. There is no later payment endpoint in this change.

Reuse the same `order_id` and create payload after a timeout. A replay returns the
existing order; changing that payload returns 409. Duplicate platform references
with a different ID return 409 with the authorized existing order as described
below. New IDs for otherwise identical internal orders represent distinct orders.
Confirmation is first-success-wins: subsequent calls return the saved order/ticket
and cannot change payment or snapshots.
Platform and table references are trimmed before hashing or saving. Verify and
confirm reject cancelled orders and inconsistent order/ticket states, including
on retries. Cancellation retries return the original saved cancellation.

### Duplicate identity and timeout recovery contract

The client must generate and persist one `order_id` UUID before its first create
attempt and keep that UUID and payload across network errors, timeouts, application
restarts, and retries. The UUID is globally unique; replay is allowed only within
the requested, authorized brand. It is not scoped to a terminal or session: another
authorized staff member in that brand can recover the same submission. Normal
session, role and brand checks run on every request, including replays.

The server stores a SHA-256 fingerprint with the order in the same transaction.
It covers brand, channel, normalized store/external/table references, order notes,
and the ordered lines (menu UUID, quantity, line notes and sorted modifier UUIDs).
JSON property order and modifier order do not affect the fingerprint. Omitted
notes and null notes are equivalent; other notes are compared exactly. Line order
is significant. Actor, current catalog values and later payment/status changes
are excluded. Fingerprints and UUIDs have no automatic expiry: they remain for the
retained order's lifetime, including cancelled orders. Do not purge orders or reuse
their UUIDs while clients can still retry; purged records cannot provide replay
protection. Legacy orders with a null fingerprint cannot be replayed as creates
and return `ORDER_ID_CONFLICT`.

For GRABFOOD/FOODPANDA, both references must be nonblank strings of at most 255
characters before persistence. Surrounding whitespace is removed using JavaScript
`trim()`. Comparison after trimming is exact and case-sensitive: no case folding,
Unicode normalization, internal whitespace removal or punctuation removal is
performed. The identity is `(order_channel, merchant_store_reference,
external_order_reference)` globally, matching the database unique constraint.
A different channel or store is a permitted lookalike. Brand is not part of this
platform identity. The same identity blocks a second order even when its new UUID,
lines or notes differ, or the original order has been confirmed or cancelled.

Create conflicts have these stable codes:

| HTTP/code                      | Meaning and client behavior                                                                                                                                                                                                                            |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `201` (saved order)            | This UUID and payload committed, or were already committed. Use the returned current order and ticket; do not create another UUID after a timeout.                                                                                                     |
| `409 DUPLICATE_PLATFORM_ORDER` | A different UUID already owns the platform identity. `existing_order` contains the current saved order only if it belongs to the requested brand; otherwise it is null. Show the duplicate screen; never automatically confirm or replace its content. |
| `409 ORDER_ID_CONFLICT`        | The UUID belongs to a different brand or was reused with changed content (or has no legacy fingerprint). No existing-order data is returned. Reconcile the original submission; this is not a successful replay.                                       |
| `409 ORDER_RETRY_REQUIRED`     | Five database-conflict attempts were exhausted. Retry with backoff using the same UUID and unchanged body; the next request will return the winner if it committed.                                                                                    |

Example duplicate response, with the full redacted OrderResponse object abbreviated
here for readability:

```json
{
  "statusCode": 409,
  "error": "Conflict",
  "code": "DUPLICATE_PLATFORM_ORDER",
  "message": "Platform order already exists.",
  "existing_order": {
    "order_id": "11111111-1111-4111-8111-111111111111",
    "status": "DRAFT"
  }
}
```

No other brand's UUID, code, lines, payment or ticket details are included, even
when a superadmin submits to a different brand route. Duplicate and replay order
objects use the same redaction as successful create/confirm responses: request
fingerprints and restricted recipe snapshots are omitted.

A lost response does not mean the operation failed. Repeat the original create to
recover its saved state, and repeat confirmation against the returned order UUID
to recover its first committed ticket/payment/snapshots. Genuine pre-commit
failures roll back the order/counter/lines or confirmation/ticket/snapshots together;
the same request can then commit normally. Concurrent attempts run in serializable
transactions with unique constraints and bounded whole-transaction retries, rather
than depending on the duplicate lookup alone. Ticket sequence values can be
consumed by failed transactions, leaving gaps without duplicate persisted numbers.

Backend regression coverage is in `src/modules/orders/orders/tests/orders.http.spec.ts` (IT-ORD-005/006
and IT-ORD-009 through IT-ORD-017), with a migrated isolated PostgreSQL test
database required via `TEST_DATABASE_URL`. This provides implementation regression
evidence; independently designed student QA and PO review remain separate. These
tests do not establish exactly-once stock deduction: Sprint 1 performs no stock
posting. This change does not update coursework checklists or sign-off status.

Every draft receives a server-generated `order_code`, such as `GC-00001`.
Create/confirm/cancel responses include `order_code`, `order_date` (the Manila calendar
date, serialized as midnight UTC), and `order_number`. Clients must continue using
the `order_id` UUID for identity, routes, and retries; codes repeat on later dates.
Clients cannot supply the code fields in request bodies.

Numbers start at 1 independently for each brand and reset at midnight in
`Asia/Manila`, shared across all channels and terminals. Five digits is the minimum
width: `GC-99999` is followed by `GC-100000`. Drafts, including abandoned or
cancelled orders, keep their numbers. Brand code changes affect future orders;
previous codes retain their saved prefix. UUID replays keep the original code,
including across midnight.

The per-brand/date database counter and order are saved in the same serializable
transaction. A failed create rolls back the increment. A new date creates a new
counter row automatically; no scheduled reset is required. A database constraint
enforces uniqueness of `(brand_id, order_date, order_number)`, while `order_code`
itself is not unique.

Pause order writes while deploying the daily-code migration, then deploy the
updated server before resuming writes. Existing orders are numbered by brand and
Manila creation date, oldest first with UUID as the tie-breaker, using each brand's
current code. UUIDs remain unchanged, and counters continue from the backfilled
maximum. Historical `created_at` timestamps are interpreted as UTC.

Serializable transactions retry database conflicts up to five attempts. Database
unique constraints protect order IDs, platform references, ticket numbers and
one ticket per order. Snapshots and status roll back if ticket creation fails.
Retries cover Prisma P2034/P2002 conflicts and pg adapter serialization/deadlock
failures (SQLSTATE 40001/40P01) surfaced during COMMIT. They use bounded backoff
with jitter. Connection failures with an unknown commit outcome are propagated;
clients recover by retrying the original identity. Stored line quantities, modifier
uniqueness, catalog prices and recipe component quantities are checked again
before confirmation to catch invalid data introduced outside the HTTP API.

Apply the checked-in Prisma migration before using these endpoints. Ticket numbers
use a global non-resetting bigint database sequence with at least three digits:
T-001, T-99999, T-100000, and onward. The character limit is 64 (already supported
by the database column), replacing the earlier seven-character requirement.
PostgreSQL's bigint ceiling is 9223372036854775807 (21 characters with T-).
Gaps are expected after rollback; numbers are never recycled. The configured
database must provide `kitchen_ticket_number_seq`; verify that it exists before
confirming orders.

Full recipe snapshots remain in the database; Order API responses omit them to
avoid exposing restricted recipe instructions. Responses include applied recipe
IDs. The ticket uses its order's saved lines and modifiers.

Sprint 1 performs no inventory balance changes, stock ledger writes or stock
availability checks on create, verify, confirm or cancel. Future inventory consumption
requires separately scoped work.

Authentication errors return `{ "code": "SESSION_TOKEN_REQUIRED", "message": "A bearer session token is required." }` or
`{ "code": "INVALID_SESSION", "message": "Invalid or expired session." }`.
