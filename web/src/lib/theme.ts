"use client";

import { useSyncExternalStore } from "react";
import { DARK_QUERY, STORAGE_KEY } from "./theme-script";

export type Theme = "light" | "dark";

function readTheme(): Theme {
  return document.documentElement.classList.contains("dark") ? "dark" : "light";
}

function savedTheme(): Theme | null {
  try {
    const value = localStorage.getItem(STORAGE_KEY);
    return value === "light" || value === "dark" ? value : null;
  } catch {
    return null;
  }
}

// How long `.theme-animating` stays on: the longest token fade in globals.css
// (520ms, toward light) plus a little slack so the last frame lands before
// element transitions come back.
const FADE_MS = 600;
let fadeTimer: ReturnType<typeof setTimeout> | undefined;

// Every theme change (the switch, the OS, another tab) goes through here.
// The color tokens are registered in globals.css, so with `.theme-animating`
// on <html> the browser eases each one to its new value and the whole page
// follows together. A second change mid-fade simply re-targets: the tokens
// turn around from wherever they are, with no jump.
function applyTheme(theme: Theme) {
  const root = document.documentElement;
  root.classList.add("theme-animating");
  root.classList.toggle("dark", theme === "dark");
  clearTimeout(fadeTimer);
  fadeTimer = setTimeout(() => root.classList.remove("theme-animating"), FADE_MS);
}

export function setTheme(theme: Theme) {
  try {
    localStorage.setItem(STORAGE_KEY, theme);
  } catch {
    // Storage blocked: the choice still applies for this page view.
  }
  applyTheme(theme);
}

function subscribe(onChange: () => void) {
  // The class on <html> is the source of truth; any tab or toggle that flips it notifies here.
  const observer = new MutationObserver(onChange);
  observer.observe(document.documentElement, { attributes: true, attributeFilter: ["class"] });

  // Until the user picks a theme, keep following the OS.
  const media = window.matchMedia(DARK_QUERY);
  const followSystem = () => {
    if (!savedTheme()) applyTheme(media.matches ? "dark" : "light");
  };
  media.addEventListener("change", followSystem);

  // Another tab changed the saved choice.
  const onStorage = (event: StorageEvent) => {
    if (event.key === STORAGE_KEY) applyTheme(savedTheme() ?? (media.matches ? "dark" : "light"));
  };
  window.addEventListener("storage", onStorage);

  return () => {
    observer.disconnect();
    media.removeEventListener("change", followSystem);
    window.removeEventListener("storage", onStorage);
  };
}

// The server can't know the theme, so it renders "light"; React then reads the
// real value from <html> right after hydration. Icons that must be right on
// first paint swap with `dark:` classes instead of reading this.
export function useTheme() {
  const theme = useSyncExternalStore(subscribe, readTheme, () => "light" as Theme);
  return {
    theme,
    toggle: () => setTheme(theme === "dark" ? "light" : "dark"),
  };
}
