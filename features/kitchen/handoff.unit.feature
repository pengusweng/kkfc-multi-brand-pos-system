@backend @unit
Feature: Handoff retrieval services

  Parameterized Jest cases share one scenario; reports retain the concrete values.

  # Jest: server/src/modules/kitchen/handoff/tests/handoff.service.spec.ts
  @UT-HAND-001
  Scenario: Retrieve a handoff by ID
    Test Case ID: UT-HAND-001
    Given a saved handoff
    When its ID is requested
    Then the service returns the saved handoff

  @UT-HAND-002
  Scenario: Reject an unknown handoff
    Test Case ID: UT-HAND-002
    Given no handoff matches the supplied ID
    When the handoff is requested
    Then the service throws HANDOFF_NOT_FOUND with status 404

  @UT-HAND-003
  Scenario: Retrieve a kitchen ticket handoff
    Test Case ID: UT-HAND-003
    Given a kitchen ticket and its saved handoff
    When the handoff is requested by ticket ID
    Then the service validates the ticket and returns its handoff

  @UT-HAND-004
  Scenario: Reject an unknown kitchen ticket
    Test Case ID: UT-HAND-004
    Given the kitchen ticket does not exist
    When its handoff is requested
    Then the service throws KITCHEN_TICKET_NOT_FOUND before querying handoffs

  @UT-HAND-005
  Scenario: Reject a ticket without a handoff
    Test Case ID: UT-HAND-005
    Given the kitchen ticket exists without a handoff
    When its handoff is requested
    Then the service throws HANDOFF_NOT_FOUND with status 404

  @UT-HAND-006
  Scenario: Retrieve paginated handoffs
    Test Case ID: UT-HAND-006
    Given saved handoffs and a requested offset and limit
    When handoffs are listed
    Then the service forwards pagination and returns handoffs and total

  @UT-HAND-007
  Scenario: Preserve the total on an empty page
    Test Case ID: UT-HAND-007
    Given saved handoffs exist before the requested page
    When a page beyond the last handoff is requested
    Then the service returns an empty array and preserves the total

  @UT-HAND-008
  Scenario: Reject a pagination offset outside the supported range
    Test Case ID: UT-HAND-008
    Given the offset exceeds the signed 32-bit integer range
    When handoffs are listed
    Then the service throws PAGINATION_UNSUPPORTED_RANGE before querying

  @UT-HAND-009
  Scenario: Retrieve handoffs for an actor
    Test Case ID: UT-HAND-009
    Given handoffs exist for an actor
    When that actor's history is requested
    Then the service returns the matching handoffs

  @UT-HAND-010
  Scenario: Return an empty actor history
    Test Case ID: UT-HAND-010
    Given no handoffs match the supplied actor ID
    When that actor's history is requested
    Then the service returns an empty array

  @UT-HAND-011
  Scenario: Propagate a handoff repository failure
    Test Case ID: UT-HAND-011
    Given a handoff retrieval query fails
    When the corresponding service method runs
    Then the original repository error is propagated

  @UT-HAND-012
  Scenario: Accept the largest supported pagination offset
    Test Case ID: UT-HAND-012
    Given the offset is the largest signed 32-bit integer
    When handoffs are listed
    Then the service forwards the offset and limit to the repository

  @UT-HAND-013
  Scenario: Propagate a kitchen ticket lookup failure
    Test Case ID: UT-HAND-013
    Given the kitchen ticket query fails
    When a handoff is requested by ticket ID
    Then the error is propagated before the handoff query runs
