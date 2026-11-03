@backend @unit
Feature: Kitchen QC services

  Parameterized Jest cases share one scenario; reports retain the concrete values.

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-001
  Scenario: passes an in-progress attempt for a ticket being checked and returns the saved attempt
    Test Case ID: UT-KQC-001
    Given an in-progress QC attempt whose ticket is CHECKING
    When the attempt is passed
    Then the service passes an in-progress attempt for a ticket being checked and returns the saved attempt

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-002
  Scenario: rejects a missing attempt before looking up the ticket or updating
    Test Case ID: UT-KQC-002
    Given the QC attempt is missing
    When the attempt is passed
    Then the service rejects a missing attempt before looking up the ticket or updating

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-003
  Scenario: rejects a missing kitchen ticket without updating the attempt
    Test Case ID: UT-KQC-003
    Given the attempt exists but its kitchen ticket is missing
    When the attempt is passed
    Then the service rejects a missing kitchen ticket without updating the attempt

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-004
  Scenario: rejects approval when the ticket status is %s
    Test Case ID: UT-KQC-004
    Given the kitchen ticket has a status other than CHECKING
    When the attempt is passed
    Then the service rejects approval when the ticket status is %s

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-005
  Scenario: rejects an attempt that is already %s
    Test Case ID: UT-KQC-005
    Given the QC attempt has already PASSED or FAILED
    When the attempt is passed
    Then the service rejects an attempt that is already %s

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-006
  Scenario: propagates an attempt lookup failure without looking up the ticket or updating
    Test Case ID: UT-KQC-006
    Given the attempt lookup fails
    When the attempt is passed
    Then the service propagates an attempt lookup failure without looking up the ticket or updating

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-007
  Scenario: propagates a ticket lookup failure without updating the attempt
    Test Case ID: UT-KQC-007
    Given the kitchen ticket lookup fails
    When the attempt is passed
    Then the service propagates a ticket lookup failure without updating the attempt

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-008
  Scenario: propagates an update failure without logging that the attempt passed
    Test Case ID: UT-KQC-008
    Given the attempt status update fails
    When the attempt is passed
    Then the service propagates an update failure without logging that the attempt passed

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-009
  Scenario: fails an in-progress attempt for a ticket being checked and returns the saved attempt
    Test Case ID: UT-KQC-009
    Given an in-progress QC attempt whose ticket is CHECKING
    When the attempt is failed
    Then the service fails an in-progress attempt for a ticket being checked and returns the saved attempt

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-010
  Scenario: rejects a missing attempt before looking up the ticket or updating
    Test Case ID: UT-KQC-010
    Given the QC attempt is missing
    When the attempt is failed
    Then the service rejects a missing attempt before looking up the ticket or updating

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-011
  Scenario: rejects a missing kitchen ticket without updating the attempt
    Test Case ID: UT-KQC-011
    Given the attempt exists but its kitchen ticket is missing
    When the attempt is failed
    Then the service rejects a missing kitchen ticket without updating the attempt

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-012
  Scenario: rejects failing an attempt when the ticket status is %s
    Test Case ID: UT-KQC-012
    Given the kitchen ticket has a status other than CHECKING
    When the attempt is failed
    Then the service rejects failing an attempt when the ticket status is %s

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-013
  Scenario: rejects an attempt that is already %s
    Test Case ID: UT-KQC-013
    Given the QC attempt has already PASSED or FAILED
    When the attempt is failed
    Then the service rejects an attempt that is already %s

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-014
  Scenario: propagates an attempt lookup failure without looking up the ticket or updating
    Test Case ID: UT-KQC-014
    Given the attempt lookup fails
    When the attempt is failed
    Then the service propagates an attempt lookup failure without looking up the ticket or updating

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-015
  Scenario: propagates a ticket lookup failure without updating the attempt
    Test Case ID: UT-KQC-015
    Given the kitchen ticket lookup fails
    When the attempt is failed
    Then the service propagates a ticket lookup failure without updating the attempt

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-016
  Scenario: propagates an update failure without logging that the attempt failed QC
    Test Case ID: UT-KQC-016
    Given the attempt status update fails
    When the attempt is failed
    Then the service propagates an update failure without logging that the attempt failed QC

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-017
  Scenario: forwards the pagination offset and limit and returns the attempts and total
    Test Case ID: UT-KQC-017
    Given QC attempts exist and an offset and limit are supplied
    When all QC attempts are listed
    Then the service forwards the pagination offset and limit and returns the attempts and total

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-018
  Scenario: preserves the total when the requested page is empty
    Test Case ID: UT-KQC-018
    Given the requested page is empty but other QC attempts exist
    When all QC attempts are listed
    Then the service preserves the total when the requested page is empty

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-019
  Scenario: accepts the largest supported pagination offset
    Test Case ID: UT-KQC-019
    Given the requested offset is the largest signed 32-bit integer
    When all QC attempts are listed
    Then the service accepts the largest supported pagination offset

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-020
  Scenario: rejects an unsupported pagination offset before querying the repository
    Test Case ID: UT-KQC-020
    Given the requested offset exceeds the signed 32-bit range
    When all QC attempts are listed
    Then the service rejects an unsupported pagination offset before querying the repository

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-021
  Scenario: validates the kitchen ticket and returns its QC attempts
    Test Case ID: UT-KQC-021
    Given a kitchen ticket exists with QC attempts
    When the ticket's QC attempts are listed
    Then the service validates the kitchen ticket and returns its QC attempts

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-022
  Scenario: returns an empty list when the kitchen ticket has no attempts
    Test Case ID: UT-KQC-022
    Given a kitchen ticket exists without QC attempts
    When the ticket's QC attempts are listed
    Then the service returns an empty list when the kitchen ticket has no attempts

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-023
  Scenario: rejects a missing kitchen ticket before querying its attempts
    Test Case ID: UT-KQC-023
    Given the kitchen ticket does not exist
    When the ticket's QC attempts are listed
    Then the service rejects a missing kitchen ticket before querying its attempts

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-024
  Scenario: queries only IN_PROGRESS attempts for the supplied checker by default
    Test Case ID: UT-KQC-024
    Given a checker has QC attempts and activeOnly is omitted
    When the checker's QC attempts are listed
    Then the service queries only IN_PROGRESS attempts for the supplied checker by default

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-025
  Scenario: paginates all statuses and counts only the supplied checker when activeOnly is false
    Test Case ID: UT-KQC-025
    Given a checker has attempts with different statuses and activeOnly is false
    When the checker's QC attempts are listed
    Then the service paginates all statuses and counts only the supplied checker when activeOnly is false

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-026
  Scenario: returns an empty list when the checker has no matching attempts
    Test Case ID: UT-KQC-026
    Given the checker has no matching QC attempts
    When the checker's QC attempts are listed
    Then the service returns an empty list when the checker has no matching attempts

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-027
  Scenario: uses the supplied transaction client instead of the default client
    Test Case ID: UT-KQC-027
    Given an existing transaction client is supplied
    When the checker's QC attempts are listed
    Then the service uses the supplied transaction client instead of the default client

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-028
  Scenario: defaults history pagination to offset 0 and limit 10
    Test Case ID: UT-KQC-028
    Given checker history is requested without explicit pagination
    When the checker's QC attempts are listed
    Then the service defaults history pagination to offset 0 and limit 10

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-029
  Scenario: preserves the checker total when a history page is empty
    Test Case ID: UT-KQC-029
    Given the checker history page is empty but matching attempts exist
    When the checker's QC attempts are listed
    Then the service preserves the checker total when a history page is empty

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-030
  Scenario: rejects an unsupported history offset before querying the database
    Test Case ID: UT-KQC-030
    Given the checker history offset exceeds the supported range
    When the checker's QC attempts are listed
    Then the service rejects an unsupported history offset before querying the database

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-031
  Scenario: ignores pagination arguments for active-only attempts
    Test Case ID: UT-KQC-031
    Given active-only lookup receives pagination arguments
    When the checker's QC attempts are listed
    Then the service ignores pagination arguments for active-only attempts

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-032
  Scenario: queries and counts history using an existing transaction client
    Test Case ID: UT-KQC-032
    Given checker history is requested within an existing transaction
    When the checker's QC attempts are listed
    Then the service queries and counts history using an existing transaction client

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-033
  Scenario: creates attempt 1 when the ticket has no previous QC attempt
    Test Case ID: UT-KQC-033
    Given the assigned checker has a ticket FOR_CHECKING with no previous attempt
    When a QC attempt is created
    Then the service creates attempt 1 when the ticket has no previous QC attempt

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-034
  Scenario: creates attempt number %i + 1 after the latest attempt FAILED
    Test Case ID: UT-KQC-034
    Given the assigned checker has a ticket FOR_CHECKING whose latest attempt FAILED
    When a QC attempt is created
    Then the service creates attempt number %i + 1 after the latest attempt FAILED

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-035
  Scenario: rejects creation with a conflict when the latest attempt is %s
    Test Case ID: UT-KQC-035
    Given the latest QC attempt is IN_PROGRESS or PASSED
    When a QC attempt is created
    Then the service rejects creation with a conflict when the latest attempt is %s

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-036
  Scenario: rejects a missing kitchen ticket without looking up the user or creating an attempt
    Test Case ID: UT-KQC-036
    Given the kitchen ticket does not exist
    When a QC attempt is created
    Then the service rejects a missing kitchen ticket without looking up the user or creating an attempt

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-037
  Scenario: rejects a ticket with status %s
    Test Case ID: UT-KQC-037
    Given the kitchen ticket is not FOR_CHECKING
    When a QC attempt is created
    Then the service rejects a ticket with status %s

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-038
  Scenario: rejects a missing user without looking up or creating a QC attempt
    Test Case ID: UT-KQC-038
    Given the ticket exists but the caller user is missing
    When a QC attempt is created
    Then the service rejects a missing user without looking up or creating a QC attempt

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-039
  Scenario: rejects the caller when the assigned checker is %s
    Test Case ID: UT-KQC-039
    Given the caller is not the ticket's assigned checker
    When a QC attempt is created
    Then the service rejects the caller when the assigned checker is %s

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-040
  Scenario: propagates a latest-attempt lookup failure without creating an attempt
    Test Case ID: UT-KQC-040
    Given the latest-attempt lookup fails
    When a QC attempt is created
    Then the service propagates a latest-attempt lookup failure without creating an attempt

  # Jest: server/src/modules/kitchen/kitchen-qc/kitchen-qc.service.spec.ts
  @UT-KQC-041
  Scenario: propagates a creation failure for a $name
    Test Case ID: UT-KQC-041
    Given persisting a first or subsequent QC attempt fails
    When a QC attempt is created
    Then the service propagates a creation failure for a $name

  @UT-KQC-042
  Scenario: Deny a checker who is not assigned to the ticket
    Given an in-progress attempt and an unassigned caller
    When the caller passes or fails the attempt
    Then the service returns a forbidden error before updating

  @UT-KQC-043
  Scenario: Use the caller transaction for QC result validation and update
    Given an in-progress attempt and a transaction
    When its assigned checker passes or fails it
    Then all database operations use that transaction
