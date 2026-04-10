"use client";

import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { clientApiFetch } from "@/lib/client-api";
import type { AdminContextResponse, SessionResponse } from "@/lib/types";

type AuthContextValue = {
  session: SessionResponse["data"] | null;
  adminContext: AdminContextResponse["data"] | null;
  orgSlug: string | null;
  loading: boolean;
  refreshSession: () => Promise<void>;
};

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: React.PropsWithChildren) {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const [session, setSession] = useState<SessionResponse["data"] | null>(null);
  const [adminContext, setAdminContext] = useState<AdminContextResponse["data"] | null>(null);
  const [loading, setLoading] = useState(true);

  const orgSlug = useMemo(() => {
    const segment = pathname.split("/")[1] ?? "";
    if (!segment) return null;
    if (segment === "api" || segment === "callback" || segment === "not-authorized") return null;
    return segment;
  }, [pathname]);

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
    if (loading) return;

    const isCallback = pathname === "/callback";
    const isNotAuthorized = pathname === "/not-authorized";
    const isOrgLogin = orgSlug ? pathname === `/${orgSlug}/login` : false;
    const isAuthPage = isCallback || isNotAuthorized || isOrgLogin;

    if (!orgSlug) {
      if (!isAuthPage) return;
    }

    if (!session?.user) {
      if (isAuthPage) return;
      const qs = searchParams?.toString();
      const here = qs ? `${pathname}?${qs}` : pathname;
      router.replace(`/${orgSlug}/login?return_to=${encodeURIComponent(here)}`);
      router.refresh();
      return;
    }

    const hasAdminRole = session.user.roles?.includes("admin");
    const org = session.organization ?? null;
    if (!hasAdminRole || !org) {
      if (isNotAuthorized) return;
      router.replace("/not-authorized");
      router.refresh();
      return;
    }

    if (orgSlug && org.slug && org.slug !== orgSlug) {
      router.replace(`/${org.slug}/dashboard`);
      router.refresh();
      return;
    }
  }, [loading, orgSlug, pathname, router, searchParams, session]);

  useEffect(() => {
    if (!session?.user?.roles?.includes("admin")) {
      setAdminContext(null);
      return;
    }
    if (!session.organization) {
      setAdminContext(null);
      return;
    }

    clientApiFetch<AdminContextResponse>("/v1/admin/context")
      .then((payload) => setAdminContext(payload.data))
      .catch(() => setAdminContext(null));
  }, [session?.organization, session?.user?.roles]);

  const value = useMemo(
    () => ({
      session,
      adminContext,
      orgSlug,
      loading,
      refreshSession,
    }),
    [adminContext, loading, orgSlug, refreshSession, session],
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
