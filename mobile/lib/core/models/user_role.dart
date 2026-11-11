/// User roles matching the backend Prisma UserRole enum.
enum UserRole {
  superadmin('SUPERADMIN'),
  manager('MANAGER'),
  recipeManager('RECIPE_MANAGER'),
  supervisor('SUPERVISOR'),
  kitchenHead('KITCHEN_HEAD'),
  inventoryStaff('INVENTORY_STAFF'),
  kitchenStaff('KITCHEN_STAFF'),
  cashierStaff('CASHIER_STAFF');

  const UserRole(this.apiValue);
  final String apiValue;

  /// Parses a role string from the API (case-insensitive, trimmed).
  static UserRole? fromApiValue(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toUpperCase();
    for (final role in UserRole.values) {
      if (role.apiValue == normalized) return role;
    }
    return null;
  }

  /// Whether this role is an authorized kitchen workspace role.
  bool get isKitchen =>
      this == UserRole.kitchenHead ||
      this == UserRole.kitchenStaff ||
      this == UserRole.supervisor;

  /// Whether this role is authorized to pass QC checks on the kitchen board.
  bool get canPassQc =>
      this == UserRole.superadmin ||
      this == UserRole.manager ||
      this == UserRole.supervisor ||
      this == UserRole.kitchenHead;

  /// Whether this role is authorized to cancel tickets.
  /// Allowed roles: SUPERADMIN, MANAGER, SUPERVISOR, and KITCHEN_HEAD.
  bool get canCancelTicket =>
      this == UserRole.superadmin ||
      this == UserRole.manager ||
      this == UserRole.supervisor ||
      this == UserRole.kitchenHead;

  /// Whether this role operates in read-only mode on the kitchen board,
  /// with the sole exception of quality control (QC) checks.
  bool get isKitchenReadOnlyExceptQc => this == UserRole.supervisor;

  /// Whether this role can change or advance ticket status on the kitchen board.
  ///
  /// Supervisors are in read-only mode across all lanes except for QC check.
  /// Kitchen staff cannot pass QC checks.
  bool canChangeTicketStatus({required bool isQcCheck}) {
    if (this == UserRole.supervisor) {
      return isQcCheck;
    }
    if (isQcCheck) {
      return canPassQc;
    }
    return true;
  }
}
