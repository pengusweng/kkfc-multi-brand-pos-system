@backend @integration @assets @audit
Feature: Assets audit logging
  Feature ID: FEAT-ASSET-IT-AUDIT
  Requirement ID: NFR-006

  As an owner,
  I want image uploads and signed download links audited,
  So that access to stored files, including hand-over photos, is traceable.

  # Jest: server/src/modules/assets/tests/assets-audit.http.spec.ts
  # Context: Assets audit logging
  @IT-ASSET-017
  Scenario: Audit uploads and issued download URLs
    Test Case ID: IT-ASSET-017
    Given a signed-in user
    When they upload an image and request its download URL
    Then ASSET_UPLOADED and ASSET_DOWNLOAD_URL_ISSUED SUCCESS rows name them as actor
    And neither row contains the object key or the signed URL

  # Jest: server/src/modules/assets/tests/assets-audit.http.spec.ts
  # Context: Assets audit logging
  @IT-ASSET-018
  Scenario: Audit storage outages but not unknown or empty keys
    Test Case ID: IT-ASSET-018
    Given a storage outage, an unknown key and an empty key
    When download URLs are requested
    Then only the outage produces an ASSET_DOWNLOAD_URL_ISSUED FAILED row with reason HTTP_503

  # Jest: server/src/modules/assets/tests/assets-audit.http.spec.ts
  # Context: Assets audit logging
  @IT-ASSET-019
  Scenario: Audit download requests without a session
    Test Case ID: IT-ASSET-019
    Given no session
    When a download URL is requested
    Then the service is not called and an ASSET_DOWNLOAD_URL_ISSUED DENIED row records SESSION_TOKEN_REQUIRED with no actor
