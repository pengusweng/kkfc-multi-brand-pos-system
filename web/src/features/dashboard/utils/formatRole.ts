// SUPERADMIN -> "Superadmin", KITCHEN_HEAD -> "Kitchen head"
export function formatRole(role: string): string {
  const words = role.toLowerCase().replaceAll("_", " ");
  return words.charAt(0).toUpperCase() + words.slice(1);
}
