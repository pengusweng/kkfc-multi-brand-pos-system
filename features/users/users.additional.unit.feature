@backend @unit @users
Feature: Additional users unit coverage
  Feature ID: FEAT-USER-UT-ADDITIONAL
  Requirement ID: FR-USER-001

  As a backend maintainer,
  I want the users behavior documented alongside its executable tests,
  So that each result can be traced to its preconditions, action, and expected outcome.

  Parameterized Jest cases share a scenario; each report entry retains the executed
  Jest name and its concrete parameter values.

  # Jest: server/src/modules/users/tests/users.service.spec.ts
  # Context: UsersService
  @UT-USER-017
  Scenario: Create each supported user role without brand assignments
    Test Case ID: UT-USER-017
    Given a superadmin caller and a supported requested role
    When a user is created
    Then the payload is saved without a brand assignment

  # Jest: server/src/modules/users/tests/users.service.spec.ts
  # Context: UsersService
  @UT-USER-018
  Scenario: Blocks managers from creating superadmins
    Test Case ID: UT-USER-018
    Given a manager attempts to create a superadmin
    When user creation is requested
    Then access is denied without saving the account

  # Jest: server/src/modules/users/tests/users.service.spec.ts
  # Context: UsersService
  @UT-USER-019
  Scenario: Restrict superadmin account changes to superadmin callers
    Test Case ID: UT-USER-019
    Given a superadmin target and a caller that may or may not be a superadmin
    When the account is updated or deactivated
    Then only a superadmin caller may modify the superadmin target

  # Jest: server/src/modules/users/tests/users.service.spec.ts
  # Context: UsersService
  @UT-USER-020
  Scenario: Allows managers to create staff without assignments
    Test Case ID: UT-USER-020
    Given a manager and a valid staff payload
    When the account is created
    Then staff creation succeeds without brand assignments

  # Jest: server/src/modules/users/tests/users.service.spec.ts
  # Context: UsersService
  @UT-USER-021
  Scenario: Looks up a username and forwards activeOnly
    Test Case ID: UT-USER-021
    Given a username lookup with activeOnly false
    When the user is retrieved
    Then the safe username lookup receives the filter instead of the UUID lookup

  # Jest: server/src/modules/users/tests/users.service.spec.ts
  # Context: UsersService / username updates
  @UT-USER-022
  Scenario: Updates to an available username and checks inactive accounts too
    Test Case ID: UT-USER-022
    Given an available replacement username
    When the account username is updated
    Then availability is checked including inactive accounts before saving

  # Jest: server/src/modules/users/tests/users.service.spec.ts
  # Context: UsersService / username updates
  @UT-USER-023
  Scenario: Reject usernames owned by active or inactive accounts
    Test Case ID: UT-USER-023
    Given the replacement username belongs to another active or inactive account
    When the account username is updated
    Then a username conflict is returned without writing

  # Jest: server/src/modules/users/tests/users.service.spec.ts
  # Context: UsersService / username updates
  @UT-USER-024
  Scenario: Skip username availability checks when the username is unchanged or omitted
    Test Case ID: UT-USER-024
    Given an update omits the username or preserves its current value
    When the account is updated
    Then the username availability check is skipped

  # Jest: server/src/modules/users/tests/users.service.spec.ts
  # Context: UsersService / username updates
  @UT-USER-025
  Scenario: Does not write if the availability lookup fails
    Test Case ID: UT-USER-025
    Given the username availability lookup fails
    When a username update is requested
    Then the lookup error is propagated without writing

  # Jest: server/src/modules/users/tests/users.service.spec.ts
  # Context: UsersService / username updates
  @UT-USER-026
  Scenario: Propagates a concurrent username conflict to the global filter
    Test Case ID: UT-USER-026
    Given a concurrent update claims the requested username
    When the account username is saved
    Then the uniqueness error is propagated for the global conflict filter

  # Jest: server/src/modules/users/tests/users.service.spec.ts
  # Context: UsersService
  @UT-USER-027
  Scenario: Does not log the user search text
    Test Case ID: UT-USER-027
    Given a user listing with a search for a person's name
    When UsersService lists users
    Then the logs record that a search was given without its text

  # Jest: server/src/modules/users/tests/users.repository.spec.ts
  # Context: UsersRepository
  @UT-USER-028
  Scenario: Filters users by status and counts both statuses
    Test Case ID: UT-USER-028
    Given a requested status of active, inactive, or all
    When UsersRepository lists users
    Then only users in that status are returned and active and inactive users are both counted

  # Jest: server/src/modules/users/tests/users.repository.spec.ts
  # Context: UsersRepository
  @UT-USER-029
  Scenario: Matches every search term against username and names
    Test Case ID: UT-USER-029
    Given a search with several space-separated terms
    When UsersRepository lists users
    Then each term must match the username, first name, or last name case-insensitively, and the counts use the same search

  # Jest: server/src/modules/users/tests/users.repository.spec.ts
  # Context: UsersRepository
  @UT-USER-030
  Scenario: Filters users and status counts by role
    Test Case ID: UT-USER-030
    Given a user listing for a single role
    When UsersRepository lists users
    Then only users with that role are returned and counted in both status counts

  # Jest: server/src/modules/users/tests/users.repository.spec.ts
  # Context: UsersRepository
  @UT-USER-031
  Scenario: Orders users by the requested column with a stable tiebreak
    Test Case ID: UT-USER-031
    Given a sort column and direction, or none
    When UsersRepository lists users
    Then users are ordered by that column, newest first by default, and ties end in user_id order
