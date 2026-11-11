"use client";

import { createContext, useContext } from "react";

export type PinPromptOptions = {
  /** Defaults to "Enter your PIN". */
  title?: string;
  /** What the PIN is approving, e.g. "Create Maria Santos's account." */
  description?: string;
};

export type WithPin = <T>(action: (pin: string) => Promise<T>, options?: PinPromptOptions) => Promise<T | undefined>;

export type PinContextValue = {
  /**
   * Asks for the signed-in user's PIN, then runs `action` with it.
   * Resolves with the action's result, or undefined if the user cancels.
   * A wrong PIN keeps the prompt open; any other error rejects.
   */
  withPin: WithPin;
  /** True while the prompt is on screen, so other dialogs can stay open beneath it. */
  isPrompting: boolean;
};

export const PinContext = createContext<PinContextValue | null>(null);

export function usePin(): PinContextValue {
  const value = useContext(PinContext);
  if (!value) throw new Error("usePin must be used inside <PinProvider>.");
  return value;
}
