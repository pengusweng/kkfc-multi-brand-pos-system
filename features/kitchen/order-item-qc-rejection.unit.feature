@backend @unit
Feature: Order item QC rejection services

  Parameterized Jest cases share one scenario; reports retain the concrete values.

  # Jest: server/src/modules/kitchen/order-item-qc-rejection/tests/order-item-qc-rejection.service.spec.ts
  @UT-QCR-001
  Scenario: creates a rejection for portion %s within the ticket quantity
    Test Case ID: UT-QCR-001
    Given an in-progress QC attempt, a CHECKING ticket, and an item with two portions
    When a rejected portion is recorded
    Then the service creates a rejection for portion %s within the ticket quantity

  # Jest: server/src/modules/kitchen/order-item-qc-rejection/tests/order-item-qc-rejection.service.spec.ts
  @UT-QCR-002
  Scenario: forwards the caller transaction to every lookup and write
    Test Case ID: UT-QCR-002
    Given a valid rejection and an existing transaction client
    When a rejected portion is recorded
    Then the service forwards the caller transaction to every lookup and write

  # Jest: server/src/modules/kitchen/order-item-qc-rejection/tests/order-item-qc-rejection.service.spec.ts
  @UT-QCR-003
  Scenario: rejects a missing QC attempt before inserting
    Test Case ID: UT-QCR-003
    Given the referenced QC attempt does not exist
    When a rejected portion is recorded
    Then the service rejects a missing QC attempt before inserting

  # Jest: server/src/modules/kitchen/order-item-qc-rejection/tests/order-item-qc-rejection.service.spec.ts
  @UT-QCR-004
  Scenario: rejects a missing order item before inserting
    Test Case ID: UT-QCR-004
    Given the referenced order item does not exist
    When a rejected portion is recorded
    Then the service rejects a missing order item before inserting

  # Jest: server/src/modules/kitchen/order-item-qc-rejection/tests/order-item-qc-rejection.service.spec.ts
  @UT-QCR-005
  Scenario: rejects a completed %s attempt
    Test Case ID: UT-QCR-005
    Given the QC attempt has already PASSED or FAILED
    When a rejected portion is recorded
    Then the service rejects a completed %s attempt

  # Jest: server/src/modules/kitchen/order-item-qc-rejection/tests/order-item-qc-rejection.service.spec.ts
  @UT-QCR-006
  Scenario: rejects creation when the ticket is %s
    Test Case ID: UT-QCR-006
    Given the kitchen ticket is not CHECKING
    When a rejected portion is recorded
    Then the service rejects creation when the ticket is %s

  # Jest: server/src/modules/kitchen/order-item-qc-rejection/tests/order-item-qc-rejection.service.spec.ts
  @UT-QCR-007
  Scenario: rejects an order item belonging to a different ticket order
    Test Case ID: UT-QCR-007
    Given the item belongs to a different order than the QC attempt's ticket
    When a rejected portion is recorded
    Then the service rejects an order item belonging to a different ticket order

  # Jest: server/src/modules/kitchen/order-item-qc-rejection/tests/order-item-qc-rejection.service.spec.ts
  @UT-QCR-008
  Scenario: rejects a portion exceeding the order item quantity
    Test Case ID: UT-QCR-008
    Given the portion number exceeds the order item quantity
    When a rejected portion is recorded
    Then the service rejects a portion exceeding the order item quantity

  # Jest: server/src/modules/kitchen/order-item-qc-rejection/tests/order-item-qc-rejection.service.spec.ts
  @UT-QCR-009
  Scenario: propagates $method failures
    Test Case ID: UT-QCR-009
    Given one of the creation lookups or the insert fails
    When a rejected portion is recorded
    Then the service propagates $method failures

  # Jest: server/src/modules/kitchen/order-item-qc-rejection/tests/order-item-qc-rejection.service.spec.ts
  @UT-QCR-010
  Scenario: preserves the database uniqueness error for an already rejected portion
    Test Case ID: UT-QCR-010
    Given the database rejects a duplicate attempt, item, and portion tuple
    When a rejected portion is recorded
    Then the service preserves the database uniqueness error for an already rejected portion

  # Jest: server/src/modules/kitchen/order-item-qc-rejection/tests/order-item-qc-rejection.service.spec.ts
  @UT-QCR-011
  Scenario: returns a rejection by its ID
    Test Case ID: UT-QCR-011
    Given a rejection exists with the supplied ID
    When the corresponding rejection lookup runs
    Then the service returns a rejection by its ID

  # Jest: server/src/modules/kitchen/order-item-qc-rejection/tests/order-item-qc-rejection.service.spec.ts
  @UT-QCR-012
  Scenario: returns the standard not-found error for an unknown rejection
    Test Case ID: UT-QCR-012
    Given the rejection does not exist
    When the corresponding rejection lookup runs
    Then the service returns the standard not-found error for an unknown rejection

  # Jest: server/src/modules/kitchen/order-item-qc-rejection/tests/order-item-qc-rejection.service.spec.ts
  @UT-QCR-013
  Scenario: $method returns matching rejections
    Test Case ID: UT-QCR-013
    Given rejections match the requested QC attempt or order item
    When the corresponding rejection lookup runs
    Then the service returns matching rejections

  # Jest: server/src/modules/kitchen/order-item-qc-rejection/tests/order-item-qc-rejection.service.spec.ts
  @UT-QCR-014
  Scenario: %s returns an empty array when nothing matches
    Test Case ID: UT-QCR-014
    Given no rejections match the requested QC attempt or order item
    When the corresponding rejection lookup runs
    Then the service returns an empty array when nothing matches

  # Jest: server/src/modules/kitchen/order-item-qc-rejection/tests/order-item-qc-rejection.service.spec.ts
  @UT-QCR-015
  Scenario: %s propagates repository failures
    Test Case ID: UT-QCR-015
    Given the requested rejection lookup fails
    When the corresponding rejection lookup runs
    Then the service propagates repository failures
