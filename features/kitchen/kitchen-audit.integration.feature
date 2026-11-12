@backend @integration @kitchen @audit
Feature: Kitchen audit logging
  Feature ID: FEAT-KITCHEN-IT-AUDIT
  Requirement ID: NFR-006

  As an owner,
  I want every kitchen ticket claim and fulfillment step audited,
  So that each ticket's path from queue to hand-over can be traced to the staff who acted.

  # Jest: server/src/modules/kitchen/kitchen-ticket/tests/kitchen-ticket-audit.http.spec.ts
  # Context: Kitchen ticket audit logging
  @IT-KT-016
  Scenario: Audit preparer and checker assignment
    Test Case ID: IT-KT-016
    Given a kitchen head
    When a preparer and a checker are assigned to a ticket
    Then KITCHEN_TICKET_PREPARER_ASSIGNED and KITCHEN_TICKET_CHECKER_ASSIGNED SUCCESS rows name the ticket

  # Jest: server/src/modules/kitchen/kitchen-ticket/tests/kitchen-ticket-audit.http.spec.ts
  # Context: Kitchen ticket audit logging
  @IT-KT-017
  Scenario: Audit claim conflicts and denials but not board reads
    Test Case ID: IT-KT-017
    Given a ticket that already has a preparer and kitchen staff reading today's board
    When the preparer is claimed again, the board is read and the staff member assigns a checker
    Then the claim is FAILED with KITCHEN_TICKET_PREPARER_ALREADY_ASSIGNED, the checker assignment is DENIED with ACCESS_DENIED and the read writes no row

  # Jest: server/src/modules/kitchen/kitchen-fulfillment/tests/kitchen-fulfillment-audit.http.spec.ts
  # Context: Kitchen fulfillment audit logging
  @IT-KFUL-019
  Scenario: Audit every fulfillment step
    Test Case ID: IT-KFUL-019
    Given a kitchen head
    When a ticket is acknowledged, prepared, sent for checking, checked, rejected and passed in QC, handed over and its order cancelled
    Then each step writes a SUCCESS row naming its ticket, QC attempt or order
    And the cancellation reason is not stored

  # Jest: server/src/modules/kitchen/kitchen-fulfillment/tests/kitchen-fulfillment-audit.http.spec.ts
  # Context: Kitchen fulfillment audit logging
  @IT-KFUL-020
  Scenario: Audit status conflicts and preparer mismatches
    Test Case ID: IT-KFUL-020
    Given a ticket in the wrong status and a ticket assigned to a different preparer
    When the tickets are advanced
    Then FAILED and DENIED rows record KITCHEN_TICKET_INVALID_STATUS and KITCHEN_TICKET_PREPARER_MISMATCH

  # Jest: server/src/modules/kitchen/kitchen-fulfillment/tests/kitchen-fulfillment-audit.http.spec.ts
  # Context: Kitchen fulfillment audit logging
  @IT-KFUL-021
  Scenario: Audit QC and cancellation denials for kitchen staff
    Test Case ID: IT-KFUL-021
    Given kitchen staff
    When they pass a QC attempt and cancel a confirmed order
    Then both are DENIED with ACCESS_DENIED and no fulfillment step runs
