@backend @integration @kitchen
Feature: Draft and kitchen fulfillment cancellation endpoints

  @IT-KFUL-001
  Scenario: Cancel an order and kitchen ticket atomically and preserve retries
    Given a confirmed or preparing order with a cancellable kitchen ticket in PostgreSQL
    When fulfillment cancellation is requested and then retried
    Then both records are cancelled and the original actor reason and timestamps are preserved

  @IT-KFUL-002
  Scenario: Reject cancellation through the wrong path or in a terminal state
    Given a ticketed order sent to the draft endpoint or a completed order handed-over ticket or wrong-brand URL
    When cancellation is requested
    Then the response is a conflict or not-found and both records remain unchanged

  @IT-KFUL-003
  Scenario: Roll back ticket cancellation if order cancellation fails
    Given a confirmed order and an injected order cancellation failure
    When fulfillment cancellation is requested
    Then neither record changes and a later retry succeeds

  @IT-KFUL-004
  Scenario: Cancel drafts through orders and preserve retry details
    Given a draft order without a kitchen ticket
    When fulfillment rejects it and the orders endpoint then cancels it
    Then its ticket stays null and repeated cancellation returns the saved result
