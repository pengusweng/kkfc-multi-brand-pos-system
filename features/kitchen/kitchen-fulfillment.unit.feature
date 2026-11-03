@backend @unit @kitchen
Feature: Kitchen fulfillment handover responses

  @UT-KFUL-001
  Scenario Outline: Return the final ticket state after handover
    Given a ready ticket belonging to a preparing <channel> order
    When the order is completed and its ticket is handed over in one transaction
    Then the returned completed order and separate ticket both contain the final handed-over ticket state and timestamps

    Examples:
      | channel   |
      | DINE_IN   |
      | TAKEAWAY  |
      | GRABFOOD  |
      | FOODPANDA |

  @UT-KFUL-002
  Scenario: Cancel an order and ticket using one transaction
    Given a brand-scoped order with a kitchen ticket
    When fulfillment cancellation is requested
    Then both services receive the same transaction and return the cancelled records

  @UT-KFUL-003
  Scenario: Direct drafts to the orders cancellation endpoint
    Given an order without a kitchen ticket
    When fulfillment cancellation is requested
    Then ORDER_HAS_NO_KITCHEN_TICKET is returned before either cancellation service writes

  @UT-KFUL-004
  Scenario: Propagate an order cancellation failure
    Given an order cancellation operation fails
    When fulfillment cancellation is requested
    Then the error propagates to the transaction owner without reporting success

  @UT-KFUL-005
  Scenario: Reject a missing or wrong-brand order
    Given an order cannot be found within the requested brand
    When fulfillment cancellation is requested
    Then a not-found response is returned before writing

  @UT-KFUL-006
  Scenario: Preserve the order when ticket cancellation fails
    Given ticket cancellation fails because the ticket was handed over
    When fulfillment cancellation is requested
    Then the order cancellation service is not called
