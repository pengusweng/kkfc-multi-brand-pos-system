-- Retire the MANAGER role. Existing managers keep access as supervisors.
BEGIN;

CREATE TYPE "user_roles_new" AS ENUM (
  'SUPERADMIN', 'RECIPE_MANAGER', 'SUPERVISOR',
  'KITCHEN_HEAD', 'INVENTORY_STAFF', 'KITCHEN_STAFF', 'CASHIER_STAFF'
);

ALTER TABLE "users" ALTER COLUMN "role" TYPE "user_roles_new"
USING (CASE "role"::text
  WHEN 'MANAGER' THEN 'SUPERVISOR'
  ELSE "role"::text
END)::"user_roles_new";

DROP TYPE "user_roles";
ALTER TYPE "user_roles_new" RENAME TO "user_roles";

COMMIT;
