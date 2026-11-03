@backend @integration
Feature: Order item QC rejection retrieval endpoints

  Parameterized Jest cases share one scenario; reports retain the concrete values.

  # Jest: server/src/modules/kitchen/order-item-qc-rejection/tests/order-item-qc-rejection.http.spec.ts
  @IT-QCR-001
  Scenario: allows %s and forwards the ID
    Test Case ID: IT-QCR-001
    Given a permitted kitchen QC role has a valid bearer session
    When the corresponding QC rejection route is requested
    Then the response succeeds and the validated ID reaches the service

  # Jest: server/src/modules/kitchen/order-item-qc-rejection/tests/order-item-qc-rejection.http.spec.ts
  @IT-QCR-002
  Scenario: denies %s before calling the service
    Test Case ID: IT-QCR-002
    Given an authenticated user has a role outside the kitchen QC roles
    When the corresponding QC rejection route is requested
    Then access is denied before the service is called

  # Jest: server/src/modules/kitchen/order-item-qc-rejection/tests/order-item-qc-rejection.http.spec.ts
  @IT-QCR-003
  Scenario: requires a bearer session
    Test Case ID: IT-QCR-003
    Given the request has no bearer session
    When the corresponding QC rejection route is requested
    Then authentication is required before the service is called

  # Jest: server/src/modules/kitchen/order-item-qc-rejection/tests/order-item-qc-rejection.http.spec.ts
  @IT-QCR-004
  Scenario: rejects invalid or expired sessions
    Test Case ID: IT-QCR-004
    Given the bearer session is invalid or expired
    When the corresponding QC rejection route is requested
    Then the session is rejected before the service is called

  # Jest: server/src/modules/kitchen/order-item-qc-rejection/tests/order-item-qc-rejection.http.spec.ts
  @IT-QCR-005
  Scenario: rejects invalid UUIDs on GET %s
    Test Case ID: IT-QCR-005
    Given a rejection, attempt, or order item identifier is not a UUID
    When the corresponding QC rejection route is requested
    Then the request is rejected before the service is called

  # Jest: server/src/modules/kitchen/order-item-qc-rejection/tests/order-item-qc-rejection.http.spec.ts
  @IT-QCR-006
  Scenario: preserves the standard rejection not-found response
    Test Case ID: IT-QCR-006
    Given the requested rejection does not exist
    When the corresponding QC rejection route is requested
    Then the response preserves ORDER_ITEM_QC_REJECTION_NOT_FOUND

  # Jest: server/src/modules/kitchen/order-item-qc-rejection/tests/order-item-qc-rejection.http.spec.ts
  @IT-QCR-007
  Scenario: returns an empty list on GET $path
    Test Case ID: IT-QCR-007
    Given the attempt or item has no matching rejections
    When the corresponding QC rejection route is requested
    Then the response contains an empty array

  # Jest: server/src/modules/kitchen/order-item-qc-rejection/tests/order-item-qc-rejection.http.spec.ts
  @IT-QCR-008
  Scenario: does not expose a %s endpoint
    Test Case ID: IT-QCR-008
    Given a caller sends a write method to a rejection retrieval route
    When the corresponding QC rejection route is requested
    Then no write endpoint is matched and the retrieval service is not called
