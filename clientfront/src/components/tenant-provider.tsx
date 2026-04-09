"use client";

import React, { createContext, useContext } from "react";

type TenantContextValue = {
  subdomain: string | null;
};

const TenantContext = createContext<TenantContextValue | null>(null);

export function TenantProvider({
  subdomain,
  children,
}: React.PropsWithChildren<{ subdomain: string | null }>) {
  return (
    <TenantContext.Provider value={{ subdomain }}>
      {children}
    </TenantContext.Provider>
  );
}

export function useTenant() {
  const value = useContext(TenantContext);
  if (!value) {
    throw new Error("useTenant must be used within TenantProvider");
  }
  return value;
}

