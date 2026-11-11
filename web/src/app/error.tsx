"use client";

import ErrorPage, { type ErrorPageProps } from "@/src/features/error/containers/error-page";

// Catches render errors from every route below the root layout, e.g. a server
// component whose fetch fails because the backend is down.
export default function AppError(props: ErrorPageProps) {
  return <ErrorPage {...props} />;
}
