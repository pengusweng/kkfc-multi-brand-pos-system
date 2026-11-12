@backend @unit @audit
Feature: Audit snapshot unit coverage
  Feature ID: FEAT-AUDIT-UT-SNAPSHOTS
  Requirement ID: NFR-006

  As an owner,
  I want creations and state changes to record what changed,
  So that values like prices, availability and statuses can be traced without storing secrets.

  # Jest: server/src/shared/audit/tests/audit-snapshots.spec.ts
  # Context: Audit snapshots
  @UT-AUDIT-018
  Scenario: Serialize snapshots and keep only changed fields
    Test Case ID: UT-AUDIT-018
    Given database values including decimals, dates and nulls
    When snapshots are serialized and compared
    Then decimals and dates become JSON strings, only changed fields are kept, and an unchanged record yields no snapshots

  # Jest: server/src/shared/audit/tests/audit-snapshots.spec.ts
  # Context: Audit snapshots
  @UT-AUDIT-019
  Scenario: Keep snapshot allowlists to real, safe columns
    Test Case ID: UT-AUDIT-019
    Given every snapshot allowlist
    When it is checked against the generated database columns
    Then every key and field is a real column and no forbidden field such as password_hash is listed

  # Jest: server/src/shared/audit/tests/audit-snapshots.spec.ts
  # Context: Audit snapshots
  @UT-AUDIT-020
  Scenario: Load snapshots safely
    Test Case ID: UT-AUDIT-020
    Given a valid record, a non-UUID ID, an entity without an allowlist and a failing read
    When snapshots are loaded
    Then only allowlisted columns are selected, invalid inputs skip the query, and a failure returns null with a constant log message

  # Jest: server/src/shared/audit/tests/audit-snapshots.spec.ts
  # Context: Audit snapshots
  @UT-AUDIT-021
  Scenario: Store snapshots on success rows only
    Test Case ID: UT-AUDIT-021
    Given before and after snapshots
    When a success row and a failure row are written
    Then only the success row stores before_data and after_data

  # Jest: server/src/shared/audit/tests/audit-snapshots.spec.ts
  # Context: Audit snapshots
  @UT-AUDIT-022
  Scenario: Reject snapshots for entities without an allowlist
    Test Case ID: UT-AUDIT-022
    Given an audited route that requests snapshots for an entity with no allowlist
    When the decorator is created
    Then an error is thrown at startup

  # Jest: server/src/shared/audit/tests/audit-snapshots.spec.ts
  # Context: Audit snapshots
  @UT-AUDIT-023
  Scenario: Read snapshots around the handler
    Test Case ID: UT-AUDIT-023
    Given update, create and failing handlers
    When the interceptor runs
    Then updates read before and after the handler, creates read only after, and failures read nothing after
