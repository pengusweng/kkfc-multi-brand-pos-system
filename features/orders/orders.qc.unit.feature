@backend @unit
Feature: Order draft snapshot persistence

  Parameterized Jest cases share one scenario; reports retain the concrete values.

  # Jest: server/src/modules/orders/orders/tests/orders.service.spec.ts
  @UT-ORD-043
  Scenario: persists $order_channel draft fields and validated item snapshots
    Test Case ID: UT-ORD-043
    Given a valid internal or platform order with menu and modifier snapshots
    When a draft order is created
    Then the persisted draft contains request fields, authenticated actor and brand, generated metadata, validated item prices and modifiers, and channel payment defaults
