import { ApiError } from "@/src/lib/api-error";

export type ErrorKind = "offline" | "unreachable" | "unexpected";

export type ErrorDescription = {
  kind: ErrorKind;
  title: string;
  body: string;
  /** Server-side hash Next attaches to errors, for matching against server logs. */
  digest?: string;
};

const COPY: Record<ErrorKind, Pick<ErrorDescription, "title" | "body">> = {
  offline: {
    title: "You're offline",
    body: "This device lost its internet connection. The page will reload on its own once you're back online.",
  },
  unreachable: {
    title: "Can't reach the server",
    body: "KKFC Web Management couldn't connect to the server. It may be restarting. Try again in a moment.",
  },
  unexpected: {
    title: "This page didn't load",
    body: "Something went wrong while loading this page. Trying again usually fixes it.",
  },
};

// Messages runtimes use for a request that never got a response.
const NETWORK_MESSAGE = /fetch failed|failed to fetch|networkerror|load failed|econnrefused/i;

function isNetworkFailure(error: unknown): boolean {
  if (error instanceof ApiError) return error.code === "NETWORK";
  if (!(error instanceof Error)) return false;
  if (NETWORK_MESSAGE.test(error.message)) return true;
  return error.cause !== undefined && isNetworkFailure(error.cause);
}

function readDigest(error: unknown): string | undefined {
  if (typeof error !== "object" || error === null || !("digest" in error)) return undefined;
  return typeof error.digest === "string" && error.digest ? error.digest : undefined;
}

// Production hides Server Component error messages, so a backend outage during a
// server render often lands as "unexpected"; its copy has to cover that case too.
export function describeError(error: unknown, online = true): ErrorDescription {
  const kind: ErrorKind = !online ? "offline" : isNetworkFailure(error) ? "unreachable" : "unexpected";
  return { kind, ...COPY[kind], digest: readDigest(error) };
}
