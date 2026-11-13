@backend @integration @auth
Feature: Additional auth integration coverage
  Feature ID: FEAT-AUTH-IT-ADDITIONAL
  Requirement ID: FR-AUTH-001

  As a backend maintainer,
  I want the auth behavior documented alongside its executable tests,
  So that each result can be traced to its preconditions, action, and expected outcome.

  Parameterized Jest cases share a scenario; each report entry retains the executed
  Jest name and its concrete parameter values.

  # Jest: server/src/modules/auth/tests/auth.http.spec.ts
  # Context: 
  @IT-AUTH-014
  Scenario: Allow superadmins to list and look up employees globally
    Test Case ID: IT-AUTH-014
    Given an authenticated superadmin and employee accounts without brand assignments
    When global employee listing and individual lookups are requested
    Then users across the fixture data are accessible without brand scoping

  # Jest: server/src/modules/auth/tests/auth.http.spec.ts
  @IT-AUTH-018
  Scenario: Require a valid PIN before creating a superadmin session
    Test Case ID: IT-AUTH-018
    Given a superadmin account with valid credentials
    When login omits the PIN, sends a wrong or malformed PIN, has no PIN configured, or is PIN-locked
    Then the response is 401 PIN_REQUIRED, 401 INVALID_PIN, 403 PIN_NOT_CONFIGURED, or 429 PIN_LOCKED
    And no session is created until the correct PIN is sent, which returns 200

  # Jest: server/src/modules/auth/tests/auth.http.spec.ts
  @IT-AUTH-019
  Scenario Outline: Let non-superadmins log in without a PIN check
    Test Case ID: IT-AUTH-019
    Given a kitchen staff account with valid credentials
    When login is sent with PIN header <pin>
    Then the response status is 200 and the PIN is never verified

    Examples:
      | pin       |
      | (none)    |
      | 9999      |
