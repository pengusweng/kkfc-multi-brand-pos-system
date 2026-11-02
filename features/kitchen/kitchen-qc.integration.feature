@backend @integration
Feature: Kitchen QC retrieval endpoints

  Parameterized Jest cases share one scenario; reports retain the concrete values.

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.http.spec.ts
  @IT-KQC-001
  Scenario: allows %s and forwards validated arguments
    Test Case ID: IT-KQC-001
    Given a permitted kitchen QC role has a valid bearer session
    When the corresponding kitchen QC retrieval endpoint is requested
    Then the response succeeds and validated arguments reach the service

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.http.spec.ts
  @IT-KQC-002
  Scenario: denies %s before calling the service
    Test Case ID: IT-KQC-002
    Given an authenticated user has a role outside the kitchen QC roles
    When the corresponding kitchen QC retrieval endpoint is requested
    Then access is denied before the service is called

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.http.spec.ts
  @IT-KQC-003
  Scenario: requires a bearer session
    Test Case ID: IT-KQC-003
    Given the request has no bearer session
    When the corresponding kitchen QC retrieval endpoint is requested
    Then authentication is required before the service is called

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.http.spec.ts
  @IT-KQC-004
  Scenario: rejects an invalid or expired session
    Test Case ID: IT-KQC-004
    Given the bearer session is invalid or expired
    When the corresponding kitchen QC retrieval endpoint is requested
    Then the response rejects the session before the service is called

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.http.spec.ts
  @IT-KQC-005
  Scenario: converts list pagination into an offset and limit
    Test Case ID: IT-KQC-005
    Given page 3 and limit 5 are supplied
    When the corresponding kitchen QC retrieval endpoint is requested
    Then the service receives offset 10 and limit 5

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.http.spec.ts
  @IT-KQC-006
  Scenario: converts activeOnly=false and paginates checker history
    Test Case ID: IT-KQC-006
    Given checker history requests activeOnly=false with page 3 and limit 5
    When the corresponding kitchen QC retrieval endpoint is requested
    Then the service receives activeOnly=false, offset 10, and limit 5

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.http.spec.ts
  @IT-KQC-007
  Scenario: accepts activeOnly=true explicitly
    Test Case ID: IT-KQC-007
    Given checker lookup explicitly requests activeOnly=true
    When the corresponding kitchen QC retrieval endpoint is requested
    Then the service receives activeOnly=true

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.http.spec.ts
  @IT-KQC-008
  Scenario: validates pagination and rejects unknown query fields on GET %s
    Test Case ID: IT-KQC-008
    Given the query has invalid pagination or an unknown field
    When the corresponding kitchen QC retrieval endpoint is requested
    Then the request is rejected before the service is called

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.http.spec.ts
  @IT-KQC-009
  Scenario: rejects invalid activeOnly=%s before calling the service
    Test Case ID: IT-KQC-009
    Given the activeOnly query value is invalid or repeated
    When the corresponding kitchen QC retrieval endpoint is requested
    Then the request is rejected before the service is called

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.http.spec.ts
  @IT-KQC-010
  Scenario: rejects an invalid UUID on GET %s
    Test Case ID: IT-KQC-010
    Given a route identifier is not a UUID
    When the corresponding kitchen QC retrieval endpoint is requested
    Then the request is rejected before the service is called

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.http.spec.ts
  @IT-KQC-011
  Scenario: preserves service not-found errors on GET $path
    Test Case ID: IT-KQC-011
    Given the service reports a missing ticket or attempt
    When the corresponding kitchen QC retrieval endpoint is requested
    Then the response preserves the service's not-found code

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.http.spec.ts
  @IT-KQC-012
  Scenario: returns an empty history when a ticket has no attempts
    Test Case ID: IT-KQC-012
    Given the ticket has no QC attempts
    When the corresponding kitchen QC retrieval endpoint is requested
    Then the response contains an empty history

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.http.spec.ts
  @IT-KQC-013
  Scenario: returns an empty result when a checker has no matching attempts
    Test Case ID: IT-KQC-013
    Given the checker has no matching QC attempts
    When the corresponding kitchen QC retrieval endpoint is requested
    Then the response contains an empty list and a zero total
