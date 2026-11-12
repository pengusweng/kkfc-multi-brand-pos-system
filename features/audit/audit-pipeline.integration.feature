@backend @integration @audit
Feature: Audit pipeline HTTP coverage
  Feature ID: FEAT-AUDIT-IT-PIPELINE
  Requirement ID: NFR-006

  As an owner,
  I want guard denials and failed actions audited through the real HTTP pipeline,
  So that rejected attempts are traceable even when no service code runs.

  # Jest: server/src/shared/audit/tests/audit-pipeline.http.spec.ts
  # Context: Audit pipeline HTTP
  @IT-AUDIT-008
  Scenario: Audit a successful action over HTTP
    Test Case ID: IT-AUDIT-008
    Given an audited action route and an authorized session
    When the action succeeds
    Then exactly one SUCCESS row is written with the response's request ID

  # Jest: server/src/shared/audit/tests/audit-pipeline.http.spec.ts
  # Context: Audit pipeline HTTP
  @IT-AUDIT-009
  Scenario: Audit guard denials
    Test Case ID: IT-AUDIT-009
    Given a missing session or a role the route does not allow
    When a guard rejects the action
    Then a DENIED row is written with the guard's error code and the known actor

  # Jest: server/src/shared/audit/tests/audit-pipeline.http.spec.ts
  # Context: Audit pipeline HTTP
  @IT-AUDIT-010
  Scenario: Audit conflicting actions
    Test Case ID: IT-AUDIT-010
    Given an action that throws a domain conflict or a unique-constraint error
    When the action fails with 409
    Then a FAILED row is written with the domain or mapped error code

  # Jest: server/src/shared/audit/tests/audit-pipeline.http.spec.ts
  # Context: Audit pipeline HTTP
  @IT-AUDIT-011
  Scenario: Skip validation errors and unaudited routes
    Test Case ID: IT-AUDIT-011
    Given an invalid route parameter or a route without @Audit
    When the request completes
    Then no audit row is written and the response still carries an x-request-id

  # Jest: server/src/shared/audit/tests/audit-pipeline.http.spec.ts
  # Context: Audit pipeline HTTP
  @IT-AUDIT-012
  Scenario: Keep responses unchanged during an audit outage
    Test Case ID: IT-AUDIT-012
    Given the audit table cannot be written
    When an audited action succeeds
    Then the client receives the normal status and body
