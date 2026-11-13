@backend @integration @brands @audit
Feature: Brands audit logging
  Feature ID: FEAT-BRND-IT-AUDIT
  Requirement ID: NFR-006

  As an owner,
  I want brand changes audited,
  So that every change to a brand can be traced to the superadmin who made it.

  # Jest: server/src/modules/brands/tests/brands-audit.http.spec.ts
  # Context: Brands audit logging
  @IT-BRND-031
  Scenario: Audit brand creation, updates and deactivation
    Test Case ID: IT-BRND-031
    Given a superadmin
    When a brand is created, updated and deactivated
    Then BRAND_CREATED, BRAND_UPDATED and BRAND_DEACTIVATED SUCCESS rows name the brand

  # Jest: server/src/modules/brands/tests/brands-audit.http.spec.ts
  # Context: Brands audit logging
  @IT-BRND-032
  Scenario: Audit duplicate codes but not missing brands
    Test Case ID: IT-BRND-032
    Given a brand code that already exists and a brand that is already inactive
    When the duplicate is created and the inactive brand is deactivated
    Then BRAND_CREATED is FAILED with DUPLICATE_RESOURCE and the not-found deactivation writes no row

  # Jest: server/src/modules/brands/tests/brands-audit.http.spec.ts
  # Context: Brands audit logging
  @IT-BRND-033
  Scenario: Audit role denials but not routine brand reads
    Test Case ID: IT-BRND-033
    Given a supervisor
    When brands are listed, a brand is viewed and a brand is created
    Then only the creation produces a BRAND_CREATED DENIED row with ACCESS_DENIED
