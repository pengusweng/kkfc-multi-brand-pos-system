@backend @integration
Feature: Paginated handoff list and actor history endpoints

  Parameterized Jest cases share one scenario; reports retain the concrete values.

  # Jest: server/src/modules/kitchen/handoff/tests/handoff.http.spec.ts
  @IT-HAND-001
  Scenario: Allow authorized roles to list handoffs
    Test Case ID: IT-HAND-001
    Given a valid session for a superadmin or kitchen head
    When the handoff list or actor history endpoint is requested without pagination parameters
    Then the corresponding service receives offset zero and limit ten and the actor ID for actor history
    And the response contains the handoffs, signed image URLs, and total

  @IT-HAND-002
  Scenario: Deny all other roles
    Test Case ID: IT-HAND-002
    Given a valid session with a role other than superadmin or kitchen head
    When the handoff list or actor history endpoint is requested
    Then the response is 403 ACCESS_DENIED and the service is not called

  @IT-HAND-003
  Scenario: Require authentication
    Test Case ID: IT-HAND-003
    Given no bearer session is supplied
    When the handoff list or actor history endpoint is requested
    Then the response is 401 and the service is not called

  @IT-HAND-004
  Scenario: Reject an invalid session
    Test Case ID: IT-HAND-004
    Given the bearer session is invalid or expired
    When the handoff list or actor history endpoint is requested
    Then the response is 401 INVALID_SESSION and the service is not called

  @IT-HAND-005
  Scenario: Convert pagination parameters
    Test Case ID: IT-HAND-005
    Given page three and limit five are supplied
    When the handoff list or actor history endpoint is requested
    Then the corresponding service receives offset ten and limit five and the actor ID for actor history

  @IT-HAND-006
  Scenario: Reject invalid pagination and unknown query parameters
    Test Case ID: IT-HAND-006
    Given a query has invalid pagination values or an unknown parameter
    When the handoff list or actor history endpoint is requested
    Then the response is 400 and the service is not called

  @IT-HAND-007
  Scenario: Preserve totals on an empty page
    Test Case ID: IT-HAND-007
    Given the requested page has no handoffs but matching handoffs exist
    When the handoff list or actor history endpoint is requested
    Then the response preserves the empty handoff array and total count

  @IT-HAND-008
  Scenario: Preserve service pagination errors
    Test Case ID: IT-HAND-008
    Given valid page and limit values produce an unsupported offset
    When the service rejects the handoff list request
    Then the response is 400 PAGINATION_UNSUPPORTED_RANGE

  @IT-HAND-009
  Scenario: Reject an invalid actor identifier
    Test Case ID: IT-HAND-009
    Given an authenticated permitted user supplies an invalid actor UUID
    When the actor handoff history endpoint is requested
    Then the response is 400 and no list service is called
