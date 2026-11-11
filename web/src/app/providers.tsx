"use client";

import { environmentManager, QueryClient, QueryClientProvider } from "@tanstack/react-query";
import type { ReactNode } from "react";
import PinProvider from "@/src/features/pin/containers/pin-provider";

let browserQueryClient: QueryClient | undefined;

function getQueryClient() {
  if (environmentManager.isServer()) return new QueryClient();

  browserQueryClient ??= new QueryClient();
  return browserQueryClient;
}

export default function Providers({ children }: { children: ReactNode }) {
  const queryClient = getQueryClient();

  return (
    <QueryClientProvider client={queryClient}>
      <PinProvider>{children}</PinProvider>
    </QueryClientProvider>
  );
}
