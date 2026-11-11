import type { User, UserRole } from "../schemas/userSchema";

export type StaffStatus = "active" | "inactive";
export type StaffStatusFilter = "all" | StaffStatus;

export type StaffMember = {
  id: string;
  name: string;
  username: string;
  role: string;
  status: StaffStatus;
};

export const ROLE_LABEL: Record<UserRole, string> = {
  SUPERADMIN: "Superadmin",
  MANAGER: "Manager",
  RECIPE_MANAGER: "Recipe Manager",
  SUPERVISOR: "Supervisor",
  KITCHEN_HEAD: "Kitchen Head",
  INVENTORY_STAFF: "Inventory Staff",
  KITCHEN_STAFF: "Kitchen Staff",
  CASHIER_STAFF: "Cashier Staff",
};

export function toStaffMember(user: User): StaffMember {
  return {
    id: user.user_id,
    name: `${user.first_name} ${user.last_name}`,
    username: user.username,
    role: ROLE_LABEL[user.role],
    status: user.is_active ? "active" : "inactive",
  };
}
