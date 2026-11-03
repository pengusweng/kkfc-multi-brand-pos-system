@backend @unit
Feature: Handoff services

  Parameterized Jest cases share one scenario; reports retain the concrete values.

  # Jest: server/src/modules/kitchen/handoff/tests/handoff.service.spec.ts
  @UT-HAND-001
  Scenario: Retrieve a handoff by ID
    Test Case ID: UT-HAND-001
    Given a saved handoff
    When its ID is requested
    Then the service returns the saved handoff with signed img_urls and no img_keys

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
    Then the service validates the ticket and returns its handoff with signed img_urls

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
    Then the service forwards pagination and returns handoffs with signed img_urls and their total

  @UT-HAND-007
  Scenario: Preserve the total on an empty page
    Test Case ID: UT-HAND-007
    Given saved handoffs exist before the requested page
    When a page beyond the last handoff is requested
    Then the service returns an empty history page with total zero and preserves the total

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
    Then the service returns the actor history page with signed img_urls and the actor total

  @UT-HAND-010
  Scenario: Return an empty actor history
    Test Case ID: UT-HAND-010
    Given no handoffs match the supplied actor ID
    When that actor's history is requested
    Then the service returns an empty history page with total zero

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

  @UT-HAND-014
  Scenario: Validate image evidence and create a handoff
    Test Case ID: UT-HAND-014
    Given a READY ticket, an active actor, no existing handoff, and two valid uploaded images
    When the handoff is created
    Then every image is checked for that actor and the original storage keys are saved
    And the saved handoff is returned with signed img_urls and success is logged

  @UT-HAND-015
  Scenario: Keep database transaction forwarding separate from asset checks
    Test Case ID: UT-HAND-015
    Given valid handoff data and a supplied database transaction
    When the handoff is created
    Then ticket, actor, duplicate, and insert operations receive the same transaction
    And asset checks receive only the actor ID and image key

  @UT-HAND-016
  Scenario: Reject creation for a missing ticket
    Test Case ID: UT-HAND-016
    Given the kitchen ticket does not exist
    When a handoff is created
    Then KITCHEN_TICKET_NOT_FOUND is returned before actor lookup, asset checks, or insertion

  @UT-HAND-017
  Scenario: Reject creation for a missing or inactive actor
    Test Case ID: UT-HAND-017
    Given the ticket exists and the active-user lookup finds no actor
    When a handoff is created
    Then USER_NOT_FOUND is returned before duplicate lookup, asset checks, or insertion

  @UT-HAND-018
  Scenario: Reject every ticket status other than READY
    Test Case ID: UT-HAND-018
    Given a ticket whose status is not READY
    When a handoff is created
    Then KITCHEN_TICKET_NOT_READY is returned before duplicate lookup, asset checks, or insertion

  @UT-HAND-019
  Scenario: Reject an existing handoff
    Test Case ID: UT-HAND-019
    Given a READY ticket already has a handoff record
    When another handoff is created
    Then KITCHEN_TICKET_HAS_EXISTING_HANDOFF is returned without asset checks or insertion

  @UT-HAND-020
  Scenario: Propagate image validation and storage failures
    Test Case ID: UT-HAND-020
    Given the asset service rejects a missing or unowned image or reports unavailable storage
    When a handoff is created
    Then the original error is propagated without insertion or a success log

  @UT-HAND-021
  Scenario: Require every image to pass validation
    Test Case ID: UT-HAND-021
    Given the first image is valid but the second image is missing
    When a handoff is created
    Then the second validation failure is propagated and no handoff is inserted

  @UT-HAND-022
  Scenario: Propagate creation database failures
    Test Case ID: UT-HAND-022
    Given a ticket lookup, actor lookup, duplicate lookup, or insertion fails
    When a handoff is created
    Then the original database error is propagated without logging success
    And failures before insertion prevent the insert from being called

  @UT-HAND-023
  Scenario: Preserve the uniqueness conflict when a concurrent handoff wins
    Test Case ID: UT-HAND-023
    Given the duplicate precheck passes but insertion raises a unique-constraint error
    When a handoff is created
    Then the original Prisma P2002 error is propagated for central error handling
    And no success is logged

  @UT-HAND-024
  Scenario: Return image URLs without exposing or mutating stored keys
    Test Case ID: UT-HAND-024
    Given a saved handoff with two image keys and storage signing returns a URL for each
    When the handoff is retrieved
    Then img_urls contains the signed URLs in the stored image order
    And img_keys is absent from the response and the repository record is unchanged

  @UT-HAND-025
  Scenario: Propagate image signing failures from handoff retrievals
    Test Case ID: UT-HAND-025
    Given URL signing fails for a handoff image
    When a handoff is retrieved by ID or ticket, by actor, or through pagination
    Then the original signing error is propagated instead of returning raw keys

  @UT-HAND-026
  Scenario: Return an empty URL array for a handoff without images
    Test Case ID: UT-HAND-026
    Given a stored handoff has an empty image key array
    When the handoff is retrieved
    Then img_urls is empty and the storage signer is not called

  @UT-HAND-027
  Scenario: Reject an unsupported actor history offset
    Test Case ID: UT-HAND-027
    Given the actor history offset exceeds the signed 32-bit range
    When the actor history is requested
    Then PAGINATION_UNSUPPORTED_RANGE is thrown before querying or signing images

  @UT-HAND-028
  Scenario: Preserve the actor total on an empty history page
    Test Case ID: UT-HAND-028
    Given the actor has handoffs before the requested page
    When an empty history page is requested
    Then the response contains no handoffs and preserves that actor's total
    And no image signing is performed

  @UT-HAND-029
  Scenario: Accept the largest supported actor history offset
    Test Case ID: UT-HAND-029
    Given the offset is the largest signed 32-bit integer
    When an actor's handoff history is requested
    Then the actor ID, offset, and limit are forwarded to the repository

  @UT-HAND-030
  Scenario: Filter actor history rows and totals consistently
    Test Case ID: UT-HAND-030
    Given handoff history is requested for one actor
    When the service queries its real repository with a mocked database client
    Then both the page query and total count use that actor ID
    And offset, limit, newest-first ordering, and the handoff ID tie-breaker are applied
    And both queries use a repeatable-read snapshot
