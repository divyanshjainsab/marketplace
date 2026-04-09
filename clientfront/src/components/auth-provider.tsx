"use client";

import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { clientApiFetch } from "@/lib/client-api";
import type { SessionResponse } from "@/lib/types";

type AuthContextValue = {
  session: SessionResponse["data"] | null;
  loading: boolean;
  refreshSession: () => Promise<void>;
};

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: React.PropsWithChildren) {
  const router = useRouter();
  const [session, setSession] = useState<SessionResponse["data"] | null>(null);
  const [loading, setLoading] = useState(true);

  const refreshSession = useCallback(async () => {
    setLoading(true);
    try {
      const payload = await clientApiFetch<SessionResponse>("/v1/session");
      setSession(payload.data);
    } catch {
      setSession(null);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    refreshSession().catch(() => null);
  }, [refreshSession]);

  useEffect(() => {
    if (!loading && !session?.user) {
      router.replace("/login");
      router.refresh();
    }
  }, [loading, router, session]);

  const value = useMemo(
    () => ({
      session,
      loading,
      refreshSession,
    }),
    [session, loading, refreshSession],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within AuthProvider");
  }
  return context;
}
