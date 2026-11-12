@backend @integration @audit
Feature: Audit trail access logging
  Feature ID: FEAT-AUDIT-IT-TRAIL-ACCESS
  Requirement ID: NFR-006

  As an owner,
  I want my own views of the audit trail kept out of it,
  So that real activity isn't buried under rows recording that I looked.

  # Jest: server/src/modules/audit/tests/audit-trail-access.http.spec.ts
  # Context: Audit trail access logging
  @IT-AUDIT-013
  Scenario: Do not audit audit trail views
    Test Case ID: IT-AUDIT-013
    Given a superadmin
    When they view the audit trail with valid filters and then with an out-of-range limit
    Then the valid view returns records and neither request writes an audit row

  # Jest: server/src/modules/audit/tests/audit-trail-access.http.spec.ts
  # Context: Audit trail access logging
  @IT-AUDIT-014
  Scenario: Deny other roles without writing audit rows
    Test Case ID: IT-AUDIT-014
    Given a manager
    When they try to view the audit trail
    Then the response is 403, no records are read, and no audit row is written
