@backend @integration @pin @audit
Feature: PIN audit logging
  Feature ID: FEAT-PIN-IT-AUDIT
  Requirement ID: NFR-006

  As an owner,
  I want action-PIN setup and changes audited,
  So that changes to the credential that authorizes sensitive actions are traceable.

  # Jest: server/src/modules/pin/tests/pin-audit.http.spec.ts
  # Context: PIN audit logging
  @IT-PIN-024
  Scenario: Audit setting and changing a PIN
    Test Case ID: IT-PIN-024
    Given a supervisor
    When they set a PIN and then change it with their password
    Then PIN_CREATED and PIN_UPDATED SUCCESS rows name their own credential
    And no row contains either PIN or the password

  # Jest: server/src/modules/pin/tests/pin-audit.http.spec.ts
  # Context: PIN audit logging
  @IT-PIN-025
  Scenario: Audit a duplicate PIN and a wrong password
    Test Case ID: IT-PIN-025
    Given a supervisor who already has a PIN and supplies a wrong password
    When they set a PIN and then change it
    Then PIN_CREATED is FAILED with EXISTING_PIN_FOUND and PIN_UPDATED is DENIED with INVALID_CREDENTIALS

  # Jest: server/src/modules/pin/tests/pin-audit.http.spec.ts
  # Context: PIN audit logging
  @IT-PIN-026
  Scenario: Audit role denials but not status reads or malformed PINs
    Test Case ID: IT-PIN-026
    Given a PIN status read, a malformed PIN and a role that cannot use PINs
    When the PIN endpoints are called
    Then only the role denial produces a PIN_CREATED DENIED row with ACCESS_DENIED
