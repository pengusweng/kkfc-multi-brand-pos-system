import { ViewTransition, type ReactNode } from "react";

// The navy rail and the KKFC wordmark persist between the login panel and the
// dashboard sidebar; the browser morphs them across the route change.
// `default="none"` keeps them still during unrelated transitions.

export function RailTransition({ children }: { children: ReactNode }) {
  return (
    <ViewTransition name="app-rail" share="app-rail" default="none">
      {children}
    </ViewTransition>
  );
}

export function WordmarkTransition({ children }: { children: ReactNode }) {
  return (
    <ViewTransition name="app-wordmark" share="app-wordmark" default="none">
      {children}
    </ViewTransition>
  );
}
