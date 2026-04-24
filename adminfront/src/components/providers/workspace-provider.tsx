"use client";

import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import useSWR from "swr";
import { usePathname, useRouter } from "next/navigation";
import { clientApiFetch } from "@/lib/client-api";
import { SELECTED_ORGANIZATION_COOKIE } from "@/lib/auth-cookies";
import { hasPermission, requiredPermissionForPath } from "@/lib/permissions";
import type { AdminContextResponse, Marketplace, Organization, SessionResponse } from "@/lib/types";

type WorkspaceContextValue = {
  session: SessionResponse["data"] | null;
  adminContext: AdminContextResponse["data"] | null;
  activeOrganization: Organization | null;
  activeOrganizationId: number | null;
  setActiveOrganizationId: (id: number) => Promise<void>;
  activeMarketplace: Marketplace | null;
  activeMarketplaceId: number | null;
  setActiveMarketplaceId: (id: number) => void;
  permissions: string[];
  currentRole: string | null;
  loading: boolean;
  refreshSession: () => Promise<void>;
};

const WorkspaceContext = createContext<WorkspaceContextValue | null>(null);
const SELECTED_ORGANIZATION_STORAGE_KEY = "af_selected_org";

function readCookie(name: string) {
  if (typeof document === "undefined") return null;

  const match = document.cookie
    .split("; ")
    .find((entry) => entry.startsWith(`${name}=`));

  return match ? decodeURIComponent(match.split("=").slice(1).join("=")) : null;
}

function persistSelectedOrganization(id: number | null) {
  if (typeof document === "undefined" || typeof window === "undefined") return;

  if (id) {
    document.cookie = `${SELECTED_ORGANIZATION_COOKIE}=${encodeURIComponent(String(id))}; Path=/; SameSite=Lax`;
    window.localStorage.setItem(SELECTED_ORGANIZATION_STORAGE_KEY, String(id));
    return;
  }

  document.cookie = `${SELECTED_ORGANIZATION_COOKIE}=; Path=/; Max-Age=0; SameSite=Lax`;
  window.localStorage.removeItem(SELECTED_ORGANIZATION_STORAGE_KEY);
}

function readPersistedSelectedOrganization() {
  if (typeof window === "undefined") return null;

  const cookieValue = readCookie(SELECTED_ORGANIZATION_COOKIE);
  if (cookieValue) {
    const parsed = Number(cookieValue);
    if (Number.isFinite(parsed) && parsed > 0) return parsed;
  }

  const stored = window.localStorage.getItem(SELECTED_ORGANIZATION_STORAGE_KEY);
  if (!stored) return null;

  const parsed = Number(stored);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : null;
}

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
  const hasAdminAccess = session?.admin_console_access ?? session?.admin_authorized ?? false;
  const tenantResolved = session?.tenant_resolved ?? false;
  const permissions = useMemo(() => session?.user?.permissions ?? [], [session?.user?.permissions]);
  const currentRole = session?.user?.current_role ?? null;
  const isSuperAdmin = session?.user?.roles?.includes("super_admin") ?? false;
  const canLoadAdminContext = isAuthenticated && hasAdminAccess && !!session?.organization?.id;

  const adminContextSwr = useSWR<AdminContextResponse>(
    canLoadAdminContext ? "/v1/admin/context" : null,
    (path: string) => clientApiFetch<AdminContextResponse>(path),
  );
  const adminContext = adminContextSwr.data?.data ?? null;

  const [activeOrganizationId, setActiveOrganizationIdState] = useState<number | null>(null);
  const [activeMarketplaceId, setActiveMarketplaceIdState] = useState<number | null>(null);

  const storageKey = useMemo(() => {
    const orgId = adminContext?.organization?.id;
    return orgId ? `af_active_marketplace:${orgId}` : null;
  }, [adminContext?.organization?.id]);

  useEffect(() => {
    if (!isAuthenticated) {
      setActiveOrganizationIdState(null);
      persistSelectedOrganization(null);
      return;
    }

    const persisted = readPersistedSelectedOrganization();
    if (persisted && persisted !== session?.user?.current_organization_id) {
      persistSelectedOrganization(persisted);
      setActiveOrganizationIdState(persisted);
      sessionSwr.mutate().catch(() => null);
      return;
    }

    const currentOrganizationId = session?.user?.current_organization_id ?? session?.organization?.id ?? null;
    setActiveOrganizationIdState(currentOrganizationId);
    persistSelectedOrganization(currentOrganizationId);
  }, [isAuthenticated, session?.organization?.id, session?.user?.current_organization_id, sessionSwr]);

  useEffect(() => {
    if (!adminContext?.organizations?.length) return;

    const availableIds = new Set(adminContext.organizations.map((organization) => organization.id));
    if (activeOrganizationId && availableIds.has(activeOrganizationId)) return;

    const fallbackId = session?.user?.current_organization_id ?? adminContext.organization.id ?? adminContext.organizations[0]?.id ?? null;
    if (!fallbackId) return;

    setActiveOrganizationIdState(fallbackId);
    persistSelectedOrganization(fallbackId);
  }, [activeOrganizationId, adminContext?.organization.id, adminContext?.organizations, session?.user?.current_organization_id]);

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

  const setActiveOrganizationId = useCallback(
    async (id: number) => {
      persistSelectedOrganization(id);
      setActiveOrganizationIdState(id);
      setActiveMarketplaceIdState(null);
      await sessionSwr.mutate();
      await adminContextSwr.mutate();
    },
    [adminContextSwr, sessionSwr],
  );

  const setActiveMarketplaceId = useCallback(
    (id: number) => {
      setActiveMarketplaceIdState(id);
      if (storageKey) {
        window.localStorage.setItem(storageKey, String(id));
      }
    },
    [storageKey],
  );

  const activeOrganization = useMemo(() => {
    const organizations = adminContext?.organizations ?? [];
    if (!organizations.length) return session?.organization ?? null;

    const id = activeOrganizationId ?? session?.user?.current_organization_id ?? adminContext?.organization?.id;
    const fallbackOrganization = adminContext?.organization ?? organizations[0] ?? null;
    return organizations.find((organization) => organization.id === id) ?? fallbackOrganization;
  }, [activeOrganizationId, adminContext?.organization, adminContext?.organizations, session?.organization, session?.user?.current_organization_id]);

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
    const requiredPermission = requiredPermissionForPath(pathname);
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

    if (requiredPermission && !hasPermission(permissions, requiredPermission, isSuperAdmin)) {
      if (pathname === "/not-authorized") return;
      router.replace("/not-authorized");
      return;
    }

    if (pathname === "/not-authorized") {
      router.replace("/dashboard");
    }
  }, [
    hasAdminAccess,
    isAuthenticated,
    isSuperAdmin,
    loading,
    pathname,
    permissions,
    router,
    session?.organization,
    tenantResolved,
  ]);

  const value = useMemo(
    () => ({
      session,
      adminContext,
      activeOrganization,
      activeOrganizationId,
      setActiveOrganizationId,
      activeMarketplace,
      activeMarketplaceId,
      setActiveMarketplaceId,
      permissions,
      currentRole,
      loading,
      refreshSession,
    }),
    [
      activeMarketplace,
      activeMarketplaceId,
      activeOrganization,
      activeOrganizationId,
      adminContext,
      currentRole,
      loading,
      permissions,
      refreshSession,
      session,
      setActiveMarketplaceId,
      setActiveOrganizationId,
    ],
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
