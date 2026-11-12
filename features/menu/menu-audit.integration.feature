@backend @integration @menu @audit
Feature: Menu audit logging
  Feature ID: FEAT-MENU-IT-AUDIT
  Requirement ID: NFR-006

  As an owner,
  I want every change to menu items, channels and modifiers audited,
  So that prices, availability and menu structure can be traced to whoever changed them.

  # Jest: server/src/modules/menu/tests/menu-audit.http.spec.ts
  # Context: Menu audit logging
  @IT-MENU-001
  Scenario: Audit every menu action against the affected record
    Test Case ID: IT-MENU-001
    Given a superadmin
    When any of the 18 menu catalog, item, availability, channel, modifier or item-modifier actions succeeds
    Then exactly one SUCCESS row records that action and table
    And creates name the new record from the response while other actions name the record in the route

  # Jest: server/src/modules/menu/tests/menu-audit.http.spec.ts
  # Context: Menu audit logging
  @IT-MENU-002
  Scenario: Audit duplicate codes but not missing records
    Test Case ID: IT-MENU-002
    Given a modifier code that already exists and a menu item that is already inactive
    When the modifier is created and the menu item is deactivated
    Then MODIFIER_CREATED is FAILED with DUPLICATE_RESOURCE and the not-found deactivation writes no row

  # Jest: server/src/modules/menu/tests/menu-audit.http.spec.ts
  # Context: Menu audit logging
  @IT-MENU-003
  Scenario: Audit kitchen staff availability changes and denied menu edits
    Test Case ID: IT-MENU-003
    Given kitchen staff
    When they list all menu items, mark an item unavailable and try to create a menu item
    Then the availability change is a SUCCESS row naming them, the create is DENIED with ACCESS_DENIED and the denied list read writes no row

  # Jest: server/src/modules/menu/tests/menu-audit.http.spec.ts
  # Context: Menu audit logging
  @IT-MENU-004
  Scenario: Record availability changes as before and after values
    Test Case ID: IT-MENU-004
    Given an available menu item
    When it is marked unavailable
    Then the MENU_ITEM_AVAILABILITY_CHANGED row stores is_available true before and false after
