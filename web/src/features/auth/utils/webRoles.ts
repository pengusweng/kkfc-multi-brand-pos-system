export const WEB_ROLES: ReadonlySet<string> = new Set(["SUPERADMIN", "RECIPE_MANAGER", "SUPERVISOR", "KITCHEN_HEAD"]);

/** Roles allowed into Staff Accounts (user management). */
export const STAFF_ACCOUNT_ROLES: ReadonlySet<string> = new Set(["SUPERADMIN"]);
