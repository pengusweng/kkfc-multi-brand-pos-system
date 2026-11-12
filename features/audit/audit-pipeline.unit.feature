@backend @unit @audit
Feature: Audit pipeline unit coverage
  Feature ID: FEAT-AUDIT-UT-PIPELINE
  Requirement ID: NFR-006

  As an owner,
  I want every action endpoint to leave a metadata-only audit record,
  So that successful, denied and failed actions can be traced to an actor.

  # Jest: server/src/shared/audit/tests/audit-pipeline.spec.ts
  # Context: AuditRecorder
  @UT-AUDIT-005
  Scenario: Record a successful audited action
    Test Case ID: UT-AUDIT-005
    Given an audited request with a session actor and a route entity ID
    When the action succeeds
    Then a SUCCESS row is written with the actor, entity, action and request ID

  # Jest: server/src/shared/audit/tests/audit-pipeline.spec.ts
  # Context: classifyFailure
  @UT-AUDIT-006
  Scenario: Classify denied and failed requests
    Test Case ID: UT-AUDIT-006
    Given a 401, 403, 429, 409, 5xx or non-HTTP error
    When the failure is classified
    Then 401, 403 and 429 are DENIED, 409 and 5xx are FAILED, and only well-formed error codes become the reason

  # Jest: server/src/shared/audit/tests/audit-pipeline.spec.ts
  # Context: classifyFailure
  @UT-AUDIT-007
  Scenario: Skip validation and not-found failures
    Test Case ID: UT-AUDIT-007
    Given a 400 validation error or a 404 not-found error
    When the failure is classified and recorded
    Then no audit row is written

  # Jest: server/src/shared/audit/tests/audit-pipeline.spec.ts
  # Context: AuditRecorder
  @UT-AUDIT-008
  Scenario: Store only the error code for a denied request
    Test Case ID: UT-AUDIT-008
    Given an unauthenticated audited request rejected with a code and a message
    When the failure is recorded
    Then a DENIED row stores the code as the reason, a null actor and no message text

  # Jest: server/src/shared/audit/tests/audit-pipeline.spec.ts
  # Context: AuditRecorder
  @UT-AUDIT-009
  Scenario: Resolve or null the actor and entity IDs
    Test Case ID: UT-AUDIT-009
    Given a non-UUID route ID or a route that resolves the actor from its result
    When a row is recorded
    Then non-UUID values are stored as null and resolved UUIDs are stored

  # Jest: server/src/shared/audit/tests/audit-pipeline.spec.ts
  # Context: AuditRecorder
  @UT-AUDIT-010
  Scenario: Survive an audit storage outage
    Test Case ID: UT-AUDIT-010
    Given the audit table cannot be written
    When a row is recorded
    Then the call resolves without throwing and logs a constant message without error details

  # Jest: server/src/shared/audit/tests/audit-pipeline.spec.ts
  # Context: AuditContextGuard
  @UT-AUDIT-011
  Scenario: Attach audit context before controller guards
    Test Case ID: UT-AUDIT-011
    Given requests with no, a safe, or an unsafe x-request-id header
    When the audit context guard runs
    Then it never blocks, attaches the route's audit metadata, and echoes a safe or generated request ID

  # Jest: server/src/shared/audit/tests/audit-pipeline.spec.ts
  # Context: AuditInterceptor
  @UT-AUDIT-012
  Scenario: Record success only for audited routes
    Test Case ID: UT-AUDIT-012
    Given audited and unaudited handlers that succeed or throw
    When the interceptor runs
    Then success is recorded only for audited handlers that succeed and results pass through unchanged

  # Jest: server/src/shared/audit/tests/audit-pipeline.spec.ts
  # Context: Audit decorators
  @UT-AUDIT-013
  Scenario: Reject invalid audit decorator options
    Test Case ID: UT-AUDIT-013
    Given a malformed action, entity or empty opt-out reason
    When the decorator is created
    Then an error is thrown at startup

  # Jest: server/src/shared/audit/tests/audit-pipeline.spec.ts
  # Context: Audit decorators
  @UT-AUDIT-014
  Scenario: Expose audit metadata on decorated handlers
    Test Case ID: UT-AUDIT-014
    Given a decorated and an undecorated handler
    When route metadata is read
    Then only the decorated handler exposes its audit options

  # Jest: server/src/shared/audit/tests/audit-coverage.spec.ts
  # Context: Audit coverage
  @UT-AUDIT-015
  Scenario: Discover application controllers and routes
    Test Case ID: UT-AUDIT-015
    Given the application module
    When controllers and routes are discovered
    Then known controllers and action routes are found and the pending list has no stale entries

  # Jest: server/src/shared/audit/tests/audit-coverage.spec.ts
  # Context: Audit coverage
  @UT-AUDIT-016
  Scenario: Require an audit decision on every action route
    Test Case ID: UT-AUDIT-016
    Given every migrated controller
    When its POST, PUT, PATCH and DELETE routes are checked
    Then each route has @Audit or @NoAudit and none has both

  # Jest: server/src/shared/audit/tests/audit-coverage.spec.ts
  # Context: Audit coverage
  @UT-AUDIT-017
  Scenario: Require auditing on sensitive reads
    Test Case ID: UT-AUDIT-017
    Given the listed sensitive GET routes
    When migrated controllers are checked
    Then every listed route exists and is audited
