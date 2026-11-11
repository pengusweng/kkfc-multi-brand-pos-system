import { expect, test } from "vitest";
import { ApiError } from "@/src/lib/api-error";
import { describeError } from "./describeError";

test("reports offline before anything else", () => {
  expect(describeError(ApiError.network(), false).kind).toBe("offline");
});

test("treats a refused server-side fetch as unreachable", () => {
  const refused = Object.assign(new Error("connect ECONNREFUSED 127.0.0.1:3000"), { code: "ECONNREFUSED" });
  const error = new TypeError("fetch failed", { cause: refused });
  expect(describeError(error).kind).toBe("unreachable");
});

test("treats the API client's network error as unreachable", () => {
  expect(describeError(ApiError.network()).kind).toBe("unreachable");
});

test("falls back to unexpected and keeps the digest", () => {
  const error = Object.assign(new Error("An error occurred in the Server Components render."), {
    digest: "3227098399",
  });
  expect(describeError(error)).toMatchObject({ kind: "unexpected", digest: "3227098399" });
});

test("ignores thrown values that aren't errors", () => {
  expect(describeError("boom")).toMatchObject({ kind: "unexpected", digest: undefined });
});
