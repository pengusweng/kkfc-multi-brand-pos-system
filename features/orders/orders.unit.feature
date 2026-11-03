@backend @unit @orders
Feature: Order catalog and payment rules

  @UT-ORD-001
  Scenario Outline: Fall back to the base price without an override
    Given an active menu item priced at 10 pesos without a channel override
    When the draft is <operation>
    Then the resulting line price is 10 pesos
    Examples:
      | operation |
      | verified  |
      | confirmed |

  @UT-ORD-002
  Scenario Outline: Reject an unavailable override
    Given a draft whose menu channel override is unavailable
    When the draft is <operation>
    Then the service rejects the request before snapshot or ticket writes
    Examples:
      | operation |
      | verified  |
      | confirmed |

  @UT-ORD-003
  Scenario Outline: Reject an unusable recipe
    Given a menu item with a recipe that is <condition>
    When its draft is confirmed
    Then the service returns a bad request before snapshot or ticket writes
    Examples:
      | condition                    |
      | missing                      |
      | inactive                     |
      | a production recipe          |
      | using zero component quantity |
      | using negative component quantity |
      | using NaN component quantity |
      | using infinite component quantity |

  @UT-ORD-004
  Scenario Outline: Accept each supported internal payment combination
    Given a <channel> draft
    When it is verified with <method> and <status>
    Then verification preserves that payment without updating the order
    Examples:
      | channel  | method   | status |
      | DINE_IN  | CASH     | UNPAID |
      | DINE_IN  | CASH     | PAID   |
      | DINE_IN  | E_WALLET | UNPAID |
      | DINE_IN  | E_WALLET | PAID   |
      | DINE_IN  | CARD     | UNPAID |
      | DINE_IN  | CARD     | PAID   |
      | TAKEAWAY | CASH     | UNPAID |
      | TAKEAWAY | CASH     | PAID   |
      | TAKEAWAY | E_WALLET | UNPAID |
      | TAKEAWAY | E_WALLET | PAID   |
      | TAKEAWAY | CARD     | UNPAID |
      | TAKEAWAY | CARD     | PAID   |

  @UT-ORD-005
  Scenario Outline: Reject incompatible payment
    Given a <channel> draft
    When confirmation requests <method> and <status>
    Then the service returns a bad request without snapshot or ticket writes
    Examples:
      | channel   | method           | status   |
      | TAKEAWAY  | PLATFORM_SETTLED | PAID     |
      | DINE_IN   | CASH             | REFUNDED |
      | GRABFOOD  | CASH             | PAID     |
      | FOODPANDA | PLATFORM_SETTLED | UNPAID   |

  @UT-ORD-006
  Scenario Outline: Reject missing operational references
    Given a create request with <references>
    When the order is created
    Then the service returns a bad request without inserting an order
    Examples:
      | references                         |
      | a whitespace-only dine-in table    |
      | a GrabFood store without an order  |
      | a Foodpanda order without a store  |
      | a whitespace-only GrabFood store   |

  @UT-ORD-044
  Scenario: Advance an order using the default client or caller transaction
    Given a confirmed order for preparation or a preparing order for completion
    When the lifecycle transition runs with or without a caller transaction
    Then only the expected source status is updated and private fields are redacted
    And completing the order records its completion time

  @UT-ORD-045
  Scenario: Reject a lifecycle transition for a missing order
    Given an order that does not exist
    When preparation or completion is requested
    Then ORDER_NOT_FOUND is returned before writing

  @UT-ORD-046
  Scenario: Reject an invalid source status for an order transition
    Given an order outside the permitted source status including terminal states
    When preparation or completion is requested
    Then ORDER_INVALID_STATUS is returned before writing

  @UT-ORD-047
  Scenario: Propagate a failed conditional order update
    Given the order status changes before the conditional update can succeed
    When preparation or completion is requested
    Then the update failure propagates without retrying

  @UT-ORD-048
  Scenario: Cancel a draft or retry its cancellation through the draft service
    Given a draft order without a kitchen ticket or its saved cancellation
    When draft cancellation is requested
    Then the cancelled order is returned without any ticket writes

  @UT-ORD-049
  Scenario: Reject orders outside the draft cancellation route
    Given an order with a kitchen ticket or a non-draft lifecycle
    When draft cancellation is requested
    Then ORDER_NOT_DRAFT is returned before writing

  @UT-ORD-050
  Scenario: Participate in the caller transaction when cancelling only the order
    Given an order and an existing transaction
    When the order cancellation service receives that transaction
    Then its queries use that transaction without opening another or writing a ticket
