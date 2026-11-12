@backend @integration @audit
Feature: Audit trail access logging
  Feature ID: FEAT-AUDIT-IT-TRAIL-ACCESS
  Requirement ID: NFR-006

  As an owner,
  I want views of the audit trail to be audited themselves,
  So that access to the record of who did what is also traceable.

  # Jest: server/src/modules/audit/tests/audit-trail-access.http.spec.ts
  # Context: Audit trail access logging
  @IT-AUDIT-013
  Scenario: Audit valid audit trail views only
    Test Case ID: IT-AUDIT-013
    Given a superadmin
    When they view the audit trail with valid filters and then with an out-of-range limit
    Then the valid view writes one AUDIT_LOGS_VIEWED SUCCESS row with its request ID and the rejected query writes none

  # Jest: server/src/modules/audit/tests/audit-trail-access.http.spec.ts
  # Context: Audit trail access logging
  @IT-AUDIT-014
  Scenario: Audit denied audit trail views
    Test Case ID: IT-AUDIT-014
    Given a manager
    When they try to view the audit trail
    Then no records are read and an AUDIT_LOGS_VIEWED DENIED row records ACCESS_DENIED
