@backend @integration @orders @audit
Feature: Orders audit logging
  Feature ID: FEAT-ORD-IT-AUDIT
  Requirement ID: NFR-006

  As an owner,
  I want order creation, confirmation and cancellation audited,
  So that every order's lifecycle can be traced to the staff member who acted.

  # Jest: server/src/modules/orders/orders/tests/orders-audit.http.spec.ts
  # Context: Orders audit logging
  @IT-ORD-040
  Scenario: Audit order actions but not read-only verification
    Test Case ID: IT-ORD-040
    Given a cashier
    When an order is created, verified, confirmed and a draft is cancelled
    Then ORDER_CREATED, ORDER_CONFIRMED and ORDER_CANCELLED SUCCESS rows name the order
    And verification writes no row

  # Jest: server/src/modules/orders/orders/tests/orders-audit.http.spec.ts
  # Context: Orders audit logging
  @IT-ORD-041
  Scenario: Audit order conflicts
    Test Case ID: IT-ORD-041
    Given a duplicate platform order and an order that is no longer a draft
    When the duplicate is created and the non-draft order is confirmed
    Then FAILED rows record DUPLICATE_PLATFORM_ORDER and ORDER_NOT_DRAFT

  # Jest: server/src/modules/orders/orders/tests/orders-audit.http.spec.ts
  # Context: Orders audit logging
  @IT-ORD-042
  Scenario: Audit role denials but not routine order reads
    Test Case ID: IT-ORD-042
    Given a cashier listing orders and kitchen staff viewing and creating one
    When the order endpoints are called
    Then only the kitchen staff creation produces an ORDER_CREATED DENIED row with ACCESS_DENIED
