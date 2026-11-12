@backend @integration @auth @audit
Feature: Auth audit logging
  Feature ID: FEAT-AUTH-IT-AUDIT
  Requirement ID: NFR-006

  As an owner,
  I want sign-ins and sign-outs audited,
  So that account access can be traced without storing credentials.

  # Jest: server/src/modules/auth/tests/auth-audit.http.spec.ts
  # Context: Auth audit logging
  @IT-AUTH-015
  Scenario: Audit a successful login
    Test Case ID: IT-AUTH-015
    Given valid credentials for a user
    When the user logs in
    Then an AUTH_LOGIN SUCCESS row names the user as actor and entity
    And the row contains no session token, password or username

  # Jest: server/src/modules/auth/tests/auth-audit.http.spec.ts
  # Context: Auth audit logging
  @IT-AUTH-016
  Scenario: Audit rejected credentials but not malformed requests
    Test Case ID: IT-AUTH-016
    Given a wrong password and a login body missing its password
    When both login attempts are made
    Then only the wrong password produces an AUTH_LOGIN DENIED row with reason INVALID_CREDENTIALS and a null actor

  # Jest: server/src/modules/auth/tests/auth-audit.http.spec.ts
  # Context: Auth audit logging
  @IT-AUTH-017
  Scenario: Audit logouts and rejected logouts
    Test Case ID: IT-AUTH-017
    Given a valid session and an expired session token
    When the user logs out, logs out everywhere, retries with the expired token and reads their profile
    Then AUTH_LOGOUT and AUTH_LOGOUT_ALL SUCCESS rows name the session and the user
    And the expired token produces an AUTH_LOGOUT DENIED row with reason INVALID_SESSION
    And reading the profile writes no row
