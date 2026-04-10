"use client";

import type { PropsWithChildren } from "react";
import { SWRConfig } from "swr";
import { ToastProvider } from "@/components/toast-provider";

export function AppProviders({ children }: PropsWithChildren) {
  return (
    <SWRConfig
      value={{
        revalidateOnFocus: false,
        shouldRetryOnError: false,
        dedupingInterval: 2_500,
        keepPreviousData: true,
      }}
    >
      <ToastProvider>{children}</ToastProvider>
    </SWRConfig>
  );
}

