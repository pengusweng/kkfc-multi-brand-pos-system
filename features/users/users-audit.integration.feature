@backend @integration @users @audit
Feature: Users audit logging
  Feature ID: FEAT-USER-IT-AUDIT
  Requirement ID: NFR-006

  As an owner,
  I want staff account changes and lookups audited,
  So that every change to an account and every view of staff data is traceable.

  # Jest: server/src/modules/users/tests/users-audit.http.spec.ts
  # Context: Users audit logging
  @IT-USER-022
  Scenario: Audit user creation, updates and deactivation
    Test Case ID: IT-USER-022
    Given a superadmin with a valid action PIN
    When a user is created, updated and deactivated
    Then USER_CREATED, USER_UPDATED and USER_DEACTIVATED SUCCESS rows name the affected user
    And no row contains the new user's password

  # Jest: server/src/modules/users/tests/users-audit.http.spec.ts
  # Context: Users audit logging
  @IT-USER-023
  Scenario: Audit PIN denials on account changes
    Test Case ID: IT-USER-023
    Given a missing, incorrect, unconfigured or locked action PIN
    When a user deactivation is attempted
    Then the service is not called and a USER_DEACTIVATED DENIED row records the PIN error code

  # Jest: server/src/modules/users/tests/users-audit.http.spec.ts
  # Context: Users audit logging
  @IT-USER-024
  Scenario: Audit sensitive staff reads
    Test Case ID: IT-USER-024
    Given a superadmin
    When users are listed and a user is viewed by username
    Then USERS_LISTED and USER_VIEWED SUCCESS rows are written, the view naming the resolved user

  # Jest: server/src/modules/users/tests/users-audit.http.spec.ts
  # Context: Users audit logging
  @IT-USER-025
  Scenario: Audit denied account actions but not missing users
    Test Case ID: IT-USER-025
    Given a protected account, a missing user and a role without access
    When the protected account is edited, the missing user is viewed and users are listed by the wrong role
    Then the protected edit and the wrong-role listing are DENIED with their codes and the missing user writes no row
