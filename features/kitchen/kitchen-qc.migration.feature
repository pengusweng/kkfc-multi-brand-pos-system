@backend @integration
Feature: Kitchen QC migration

  Parameterized Jest cases share one scenario; reports retain the concrete values.

  # Jest: server/src/database/tests/migrations.integration.spec.ts
  @IT-KQC-014
  Scenario: stores rejection-only portion history and enforces keys and required values
    Test Case ID: IT-KQC-014
    Given an isolated database schema with kitchen tickets, users, and order items
    When the QC migration is applied and QC history is inserted
    Then defaults, uniqueness, positive numbering, descriptions, enum values, and foreign keys are enforced while passing attempts need no rejection rows
