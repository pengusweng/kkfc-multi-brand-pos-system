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

  @IT-KFUL-005
  Scenario: Accept permitted roles and use the session actor
    Given a valid session with a role permitted for the fulfillment action
    When a fulfillment action is requested
    Then the response is 200 and validated arguments with the session actor reach the matching service

  @IT-KFUL-006
  Scenario: Require authentication on every fulfillment action
    Given no bearer session
    When a fulfillment action is requested
    Then the response is 401 before calling its service

  @IT-KFUL-007
  Scenario: Reject expired or invalid fulfillment sessions
    Given an expired or invalid session
    When a fulfillment action is requested
    Then INVALID_SESSION is returned before calling its service

  @IT-KFUL-008
  Scenario: Validate ticket attempt and order UUIDs
    Given a valid session and a malformed ticket attempt or order UUID
    When a fulfillment action is requested
    Then the response is 400 before calling its service

  @IT-KFUL-009
  Scenario: Preserve business validation failures from fulfillment services
    Given a fulfillment service rejects a missing resource unauthorized caller or invalid state
    When its endpoint is requested
    Then the corresponding 404 403 or 409 response is preserved

  @IT-KFUL-010
  Scenario: Validate nested QC rejection input
    Given a missing empty malformed or spoofed QC rejection request
    When a QC attempt rejection is requested
    Then the response is 400 before calling the service

  @IT-KFUL-011
  Scenario: Validate supplied handover image keys
    Given empty null malformed or oversized image keys or a spoofed actor
    When handover is requested
    Then the response is 400 before calling the service

  @IT-KFUL-012
  Scenario: Allow the handover service to decide whether images are required
    Given a valid session and no handover images
    When handover is requested with no body or an empty object
    Then the service receives an absent image DTO and enforces delivery requirements

  @IT-KFUL-013
  Scenario: Validate fulfillment cancellation input
    Given an invalid cancellation reason or a spoofed actor
    When fulfillment cancellation is requested
    Then the response is 400 before calling the service

  @IT-KFUL-014
  Scenario: Validate the cancellation brand UUID
    Given a malformed brand UUID and an authenticated session
    When fulfillment cancellation is requested
    Then the response is 400 before calling the service

  @IT-KFUL-015
  Scenario: Complete the kitchen workflow through authenticated endpoints
    Given a confirmed order and assigned preparer and checker
    When staff prepare reject rework pass QC and hand over the order
    Then the order is completed and the ticket is handed over

  @IT-KFUL-016
  Scenario: Upload handover images as the session user
    Given authenticated handover with image files
    When the handover endpoint is requested
    Then the uploaded image keys reach the service

  @IT-KFUL-017
  Scenario: Reject too many handover images
    Given more than five uploaded image files
    When the handover endpoint is requested
    Then the response is 400 before any upload or handover

  @IT-KFUL-018
  Scenario: Deny roles without access to a fulfillment action
    Given an authenticated user whose role is not permitted for the action
    When the fulfillment action is requested
    Then the response is 403 before calling the service
