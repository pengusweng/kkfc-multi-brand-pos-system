@backend @integration @audit
Feature: Audit snapshot HTTP coverage
  Feature ID: FEAT-AUDIT-IT-SNAPSHOTS
  Requirement ID: NFR-006

  As an owner,
  I want snapshots recorded through the real HTTP pipeline,
  So that every update and creation shows exactly what changed.

  # Jest: server/src/shared/audit/tests/audit-snapshots.http.spec.ts
  # Context: Audit snapshots HTTP
  @IT-AUDIT-015
  Scenario: Store only changed fields for an update
    Test Case ID: IT-AUDIT-015
    Given a menu item whose price changes from 150 to 165
    When the update succeeds
    Then before_data holds only the old price and after_data only the new price

  # Jest: server/src/shared/audit/tests/audit-snapshots.http.spec.ts
  # Context: Audit snapshots HTTP
  @IT-AUDIT-016
  Scenario: Store the new record for a creation
    Test Case ID: IT-AUDIT-016
    Given a newly created menu item
    When the creation succeeds
    Then after_data holds every allowlisted column and before_data is empty

  # Jest: server/src/shared/audit/tests/audit-snapshots.http.spec.ts
  # Context: Audit snapshots HTTP
  @IT-AUDIT-017
  Scenario: Store no snapshots for no-op or rejected updates
    Test Case ID: IT-AUDIT-017
    Given an update that changes nothing and an update rejected with a conflict
    When both are audited
    Then neither row stores before_data or after_data
