"use client";

import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import useSWR from "swr";
import { usePathname, useRouter } from "next/navigation";
import { clientApiFetch } from "@/lib/client-api";
import type { AdminContextResponse, Marketplace, SessionResponse } from "@/lib/types";

type WorkspaceContextValue = {
  session: SessionResponse["data"] | null;
  adminContext: AdminContextResponse["data"] | null;
  activeMarketplace: Marketplace | null;
  activeMarketplaceId: number | null;
  setActiveMarketplaceId: (id: number) => void;
  loading: boolean;
  refreshSession: () => Promise<void>;
};

const WorkspaceContext = createContext<WorkspaceContextValue | null>(null);

function sanitizeReturnTo(pathname: string, qs: string) {
  const normalized = qs.startsWith("?") ? qs : qs ? `?${qs}` : "";
  const here = normalized ? `${pathname}${normalized}` : pathname;
  if (!here.startsWith("/")) return "/dashboard";
  if (here.startsWith("//")) return "/dashboard";
  return here;
}

export function WorkspaceProvider({ children }: React.PropsWithChildren) {
  const router = useRouter();
  const pathname = usePathname();

  const sessionSwr = useSWR<SessionResponse>("/v1/me", (path: string) => clientApiFetch<SessionResponse>(path));
  const session = sessionSwr.data?.data ?? null;
  const isAuthenticated = session?.authenticated ?? false;
  const hasAdminAccess = session?.admin_authorized ?? false;
  const tenantResolved = session?.tenant_resolved ?? false;
  const canLoadAdminContext = isAuthenticated && hasAdminAccess && !!session?.organization?.id;

  const adminContextSwr = useSWR<AdminContextResponse>(
    canLoadAdminContext ? "/v1/admin/context" : null,
    (path: string) => clientApiFetch<AdminContextResponse>(path),
  );
  const adminContext = adminContextSwr.data?.data ?? null;

  const [activeMarketplaceId, setActiveMarketplaceIdState] = useState<number | null>(null);

  const storageKey = useMemo(() => {
    const orgId = adminContext?.organization?.id;
    return orgId ? `af_active_marketplace:${orgId}` : null;
  }, [adminContext?.organization?.id]);

  useEffect(() => {
    if (!adminContext?.marketplaces?.length) return;
    const marketplaces = adminContext.marketplaces;
    const sessionMarketplaceId = session?.marketplace?.id ?? null;

    let preferred: number | null = null;
    if (storageKey) {
      const stored = window.localStorage.getItem(storageKey);
      const parsed = stored ? Number(stored) : NaN;
      if (Number.isFinite(parsed) && marketplaces.some((m) => m.id === parsed)) {
        preferred = parsed;
      }
    }

    if (!preferred && sessionMarketplaceId && marketplaces.some((m) => m.id === sessionMarketplaceId)) {
      preferred = sessionMarketplaceId;
    }

    preferred ||= marketplaces[0].id;
    setActiveMarketplaceIdState(preferred);
  }, [adminContext?.marketplaces, session?.marketplace?.id, storageKey]);

  const setActiveMarketplaceId = useCallback(
    (id: number) => {
      setActiveMarketplaceIdState(id);
      if (storageKey) {
        window.localStorage.setItem(storageKey, String(id));
      }
    },
    [storageKey],
  );

  const activeMarketplace = useMemo(() => {
    if (!adminContext?.marketplaces?.length) return null;
    const id = activeMarketplaceId ?? adminContext.marketplaces[0].id;
    return adminContext.marketplaces.find((m) => m.id === id) ?? adminContext.marketplaces[0];
  }, [activeMarketplaceId, adminContext?.marketplaces]);

  const refreshSession = useCallback(async () => {
    await sessionSwr.mutate();
    if (canLoadAdminContext) await adminContextSwr.mutate();
  }, [adminContextSwr, canLoadAdminContext, sessionSwr]);

  const loading = sessionSwr.isLoading || (canLoadAdminContext && adminContextSwr.isLoading);

  useEffect(() => {
    if (loading) return;

    const isAuthRoute = pathname === "/login" || pathname === "/callback" || pathname === "/not-authorized";
    if (!isAuthenticated) {
      if (isAuthRoute) return;
      const returnTo =
        typeof window === "undefined"
          ? "/dashboard"
          : sanitizeReturnTo(window.location.pathname, window.location.search);
      router.replace(`/login?return_to=${encodeURIComponent(returnTo)}`);
      return;
    }

    if (pathname === "/login") {
      router.replace("/dashboard");
      return;
    }

    if (!hasAdminAccess || !tenantResolved || !session?.organization) {
      if (pathname === "/not-authorized") return;
      router.replace("/not-authorized");
      return;
    }

    if (pathname === "/not-authorized") {
      router.replace("/dashboard");
    }
  }, [hasAdminAccess, isAuthenticated, loading, pathname, router, session?.organization, tenantResolved]);

  const value = useMemo(
    () => ({
      session,
      adminContext,
      activeMarketplace,
      activeMarketplaceId,
      setActiveMarketplaceId,
      loading,
      refreshSession,
    }),
    [activeMarketplace, activeMarketplaceId, adminContext, loading, refreshSession, session, setActiveMarketplaceId],
  );

  return <WorkspaceContext.Provider value={value}>{children}</WorkspaceContext.Provider>;
}

export function useWorkspace() {
  const context = useContext(WorkspaceContext);
  if (!context) {
    throw new Error("useWorkspace must be used within WorkspaceProvider");
  }
  return context;
}
