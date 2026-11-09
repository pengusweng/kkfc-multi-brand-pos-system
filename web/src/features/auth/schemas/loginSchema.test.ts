import { expect, test } from "vitest";
import { loginSchema } from "./loginSchema";

test("trims the username while preserving password whitespace", () => {
  expect(loginSchema.parse({ username: "  manager  ", password: " password " }))
    .toEqual({ username: "manager", password: " password " });
});
