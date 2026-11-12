# Issue #64 QA — kitchen ticket status flow

Date: 2026-11-12. Commit: `48adf36`.
Issue: https://github.com/pengusweng/kkfc-multi-brand-pos-system/issues/64

**Result: the backend's core valid/invalid transition requirement and AC-06 pass.**
Full Flutter workflow evidence and the broader review questions are not all
complete. No application source was changed and no issue comment was posted.

## Executed checks

| Check | Result |
| --- | --- |
| Kitchen unit suites | 6 suites, 295 passed |
| Kitchen HTTP suites (mocked services/persistence) | 5 suites, 423 passed |
| Selected real PostgreSQL HTTP workflow cases | 16 passed; 98 unrelated cases excluded by name filter |
| Independent real PostgreSQL probes | 79 passed |

All 24 committed migrations applied to a new disposable database on loopback
port 5544, database `pos_mobile_test`, Docker project `kkfc-issue64-qa`.
The development database was not modified. The QA container/network were removed
after testing. The pg adapter emitted a concurrent-client-query deprecation
warning; it did not fail the checks.

## Verified behavior

The independent service-level database matrix covers eight actions across all
nine persisted status values (72 combinations), using assigned actors. Legal
transitions persist the expected state and applicable timestamp. Invalid
transitions return 409 and preserve the full saved ticket record. Cancellation
of an already cancelled ticket is accepted as an idempotent operation.

```text
QUEUED → ACKNOWLEDGED → PREPARING → FOR_CHECKING → CHECKING → READY → HANDED_OVER
                                      ↑            │
                                      └─ REWORKING ←┘ (failed QC)
```

Cancellation is allowed from nonterminal states; handed-over tickets cannot be
cancelled. Additional persisted probes verify five wrong-assignee 403 cases
without state changes and a concurrent acknowledgement with exactly one winning
write whose timestamp is preserved.

The AC-06 probe executes the fulfillment services with real transactions:

1. Prepare and check a ticket; reject a portion with a persisted reason.
2. Confirm that the ticket becomes REWORKING.
3. Attempt to approve the failed attempt and hand over the ticket: both fail
   with 409, leaving the saved ticket unchanged.
4. Send the corrected ticket for checking and create attempt number 2.
5. Approve the new attempt: READY is allowed, followed by handover and a
   COMPLETED order.

Selected existing real HTTP cases independently cover authenticated full
preparation/rejection/rework/recheck/handover (`IT-KFUL-015`), saved preparer and
checker assignments, concurrent assignment claims (`IT-KT-014/015`), cancellation
rules, rollback and retries (`IT-KFUL-001/002/003/004`). Unit/isolated HTTP suites
also cover role restrictions, session actors, malformed/extra fields, status
preconditions, QC attempts, retrieval projections and transaction delegation.

## Remaining review evidence

- **Flutter is not complete/observed:** `mobile/lib/app/router.dart:84` maps the
  kitchen-tickets route to `LoginScreen()`. Shared ticket-card widgets exist,
  but no working kitchen status page was established. No Flutter device run or
  kitchen-screen observation is claimed.
- **Audit evidence remains incomplete:** #83 is not integrated into kitchen
  status changes or general permission denials. Passing transition tests do not
  establish durable actor/event audit records.
- **Active-list semantics need an explicit decision:** today's ticket query
  filters by Manila date, without excluding terminal statuses. Assignee lists
  exclude HANDED_OVER by default, but can include CANCELLED. The API may be
  intentionally returning today's history; do not declare an active-only queue
  correct without an agreed definition.
- **QC reason projection:** committed QC migrations applied and the persisted
  rejection/rework path passed. The ticket repository's ordinary list projection
  includes ticket/item data, not nested QC rejection reasons. This run does not
  establish that a kitchen ticket-list UI displays the latest reason, as raised
  by the #85 review question.
- **Alerts:** no device evidence or team approval for the clock origin,
  8/10/15 meanings or audible settings was established. These are not inferred
  from passing status tests.
- Shared employee brand access is the current backend model. The broader
  all-brand-read/scoped-write policy, forged-brand scenarios and team acceptance
  are not fully certified by this run.

The issue's sole original Done when item, “Valid and invalid transitions tested
(AC-06),” is satisfied for the backend in this run. QA can attach this evidence
for backend acceptance. If #64 also requires observed Flutter behavior or all
Phase 6 review points, retain those as pending and do not claim a full-system
pass. The review text itself explicitly calls its additional points questions,
not approved replacement acceptance criteria.

## Reproduce

From the repository root:

```powershell
docker compose -p kkfc-issue64-qa -f docker-compose.mobile-test.yml up -d db
cd server
$env:DATABASE_URL='postgresql://pos:mobile-test-only@127.0.0.1:5544/pos_mobile_test'
$env:TEST_DATABASE_URL=$env:DATABASE_URL
npm.cmd run prisma:generate
node node_modules/prisma/build/index.js migrate deploy
node node_modules/jest/bin/jest.js --config jest-unit.json --runInBand --testPathPatterns='modules/kitchen' --reporters=default --silent
node node_modules/jest/bin/jest.js --config jest-integration.json --runInBand --testPathPatterns='modules/kitchen' --reporters=default --silent
node node_modules/jest/bin/jest.js --config jest-integration.json --runInBand --runTestsByPath src/modules/orders/orders/tests/orders.http.spec.ts --testNamePattern='IT-KFUL-015|IT-KT-014|IT-KT-015|IT-KFUL-001|IT-KFUL-002|IT-KFUL-003|IT-KFUL-004' --reporters=default --silent
node --test qa/issue64.transitions.test.cjs
cd ..
docker compose -p kkfc-issue64-qa -f docker-compose.mobile-test.yml down
```

Run the database suites/probes sequentially. The matrix resets a synthetic
ticket directly to each source state for testing; it does not expose an API
for arbitrary state changes. Its lower-level ready/check transitions are tested
separately from the public fulfillment/QC workflow.
