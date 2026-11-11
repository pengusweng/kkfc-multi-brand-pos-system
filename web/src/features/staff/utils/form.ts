type FieldMeta = { isTouched: boolean; isValid: boolean; errors: unknown[] };

// First validation message for a touched TanStack Form field, if any.
export function fieldError(meta: FieldMeta): string | undefined {
  if (!meta.isTouched || meta.isValid) return undefined;
  const first = meta.errors[0];
  if (typeof first === "string") return first;
  if (first && typeof first === "object" && "message" in first) return String(first.message);
  return undefined;
}
