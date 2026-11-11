"use client";

import { useRef, useState, type ReactNode } from "react";
import PinModal, { type PinRequest } from "../components/organisms/pin-modal";
import { PinContext, type WithPin } from "../hooks/usePin";

// Mounted once for the whole app: any feature calls `withPin(action)` and this
// renders the single PIN prompt for it. (React Compiler memoizes the context value.)
export default function PinProvider({ children }: { children: ReactNode }) {
  // The request outlives `open` so the prompt keeps its content while it animates out.
  const [request, setRequest] = useState<PinRequest | null>(null);
  const [open, setOpen] = useState(false);
  const nextId = useRef(0);

  const withPin: WithPin = (action, options = {}) =>
    new Promise((resolve, reject) => {
      nextId.current += 1;
      setRequest({
        id: nextId.current,
        ...options,
        run: action,
        resolve: resolve as (value: unknown) => void,
        reject,
      });
      setOpen(true);
    });

  return (
    <PinContext.Provider value={{ withPin, isPrompting: open }}>
      {children}
      <PinModal request={request} open={open} onFinish={() => setOpen(false)} />
    </PinContext.Provider>
  );
}
