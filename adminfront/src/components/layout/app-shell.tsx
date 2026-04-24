"use client";

import { useState, type PropsWithChildren } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import LogoutButton from "@/components/logout-button";
import { useWorkspace } from "@/components/providers/workspace-provider";
import { NAV_ITEMS } from "@/lib/nav";
import { cn } from "@/lib/cn";
import { hasPermission } from "@/lib/permissions";

function startTour() {
  window.dispatchEvent(new CustomEvent("adminfront:start-tour"));
}

export default function AppShell({ children }: PropsWithChildren) {
  const pathname = usePathname();
  const {
    adminContext,
    session,
    loading,
    activeOrganization,
    activeOrganizationId,
    setActiveOrganizationId,
    activeMarketplace,
    activeMarketplaceId,
    setActiveMarketplaceId,
    permissions,
    currentRole,
  } = useWorkspace();
  const [mobileOpen, setMobileOpen] = useState(false);

  const orgName = activeOrganization?.name ?? adminContext?.organization?.name ?? session?.organization?.name ?? "Your organization";
  const storeName = activeMarketplace?.name ?? session?.marketplace?.name ?? "Your store";
  const isSuperAdmin = session?.user?.roles?.includes("super_admin") ?? false;
  const visibleNavItems = NAV_ITEMS.filter((item) =>
    item.permission ? hasPermission(permissions, item.permission, isSuperAdmin) : true,
  );

  return (
    <div className="min-h-screen text-slate-900">
      <div className="mx-auto flex min-h-screen max-w-[1680px] gap-4 px-3 py-3 sm:gap-6 sm:px-4 sm:py-4 lg:px-6">
        <aside
          data-tour="sidebar"
          className="hidden w-72 shrink-0 flex-col rounded-[2rem] border border-slate-900/10 bg-slate-950 px-5 py-6 text-slate-100 shadow-[0_24px_80px_rgba(15,23,42,0.22)] lg:flex"
        >
          <div className="space-y-2">
            <p className="text-xs uppercase tracking-[0.35em] text-slate-400">Admin</p>
            <h1 className="text-2xl font-semibold leading-tight text-white">{orgName}</h1>
            <p className="text-sm text-slate-400">
              {loading ? "Refreshing session..." : session?.user?.email ?? "Signed in"}
            </p>
            <div className="rounded-2xl border border-white/10 bg-white/5 px-4 py-3">
              <p className="text-xs uppercase tracking-[0.25em] text-slate-500">Store</p>
              <p className="mt-2 text-sm font-semibold text-white">{storeName}</p>
            </div>
          </div>

          <nav className="mt-8 flex flex-1 flex-col gap-2">
            {visibleNavItems.map((item) => {
              const active = pathname === item.href || pathname.startsWith(`${item.href}/`);
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  data-tour={item.tourId}
                  className={cn(
                    "rounded-2xl px-4 py-3 text-sm font-medium transition",
                    active ? "bg-white text-slate-950" : "text-slate-300 hover:bg-white/10 hover:text-white",
                  )}
                >
                  {item.label}
                </Link>
              );
            })}
          </nav>

          <div className="mt-4 space-y-3">
            <button
              type="button"
              onClick={startTour}
              data-tour="take-tour"
              className="w-full rounded-2xl border border-white/15 bg-white/5 px-4 py-3 text-left text-sm font-medium text-white hover:bg-white/10"
            >
              Take a Tour
            </button>
            <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
              <p className="text-xs uppercase tracking-[0.25em] text-slate-500">Access</p>
              <p className="mt-2 text-sm text-slate-300">
                {currentRole ? currentRole.replace(/_/g, " ") : "Limited"}
              </p>
            </div>
          </div>
        </aside>

        <div className="flex min-h-full flex-1 flex-col overflow-hidden rounded-[1.5rem] border border-slate-900/10 bg-white/80 shadow-[0_24px_80px_rgba(15,23,42,0.12)] backdrop-blur sm:rounded-[2rem]">
          <header
            data-tour="topbar"
            className="flex flex-col gap-4 border-b border-slate-900/10 px-4 py-4 sm:px-6 sm:py-5 lg:flex-row lg:items-center lg:justify-between"
          >
            <div className="flex items-center gap-3">
              <button
                type="button"
                className="inline-flex items-center justify-center rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm font-semibold text-slate-900 shadow-sm hover:bg-slate-50 lg:hidden"
                onClick={() => setMobileOpen(true)}
                aria-label="Open navigation"
              >
                Menu
              </button>
              <div>
                <p className="text-xs uppercase tracking-[0.3em] text-slate-500">Organization</p>
                <h2 className="mt-2 text-xl font-semibold tracking-tight text-slate-950 sm:text-2xl">{orgName}</h2>
                <p className="mt-1 text-sm text-slate-600">This is your store workspace.</p>
              </div>
            </div>
            <div className="flex flex-col gap-3 sm:flex-row sm:flex-wrap sm:items-center lg:justify-end">
              {adminContext?.organizations && adminContext.organizations.length > 1 ? (
                <label className="w-full rounded-full border border-slate-200 bg-slate-50 px-4 py-2 text-sm text-slate-700 sm:w-auto">
                  <span className="sr-only">Active organization</span>
                  <select
                    value={activeOrganizationId ?? adminContext.organization.id}
                    onChange={(e) => {
                      setActiveOrganizationId(Number(e.target.value)).catch(() => null);
                    }}
                    className="w-full bg-transparent text-sm outline-none sm:min-w-[11rem]"
                  >
                    {adminContext.organizations.map((organization) => (
                      <option key={organization.id} value={organization.id}>
                        {organization.name}
                      </option>
                    ))}
                  </select>
                </label>
              ) : null}
              {adminContext?.marketplaces?.length ? (
                <label className="w-full rounded-full border border-slate-200 bg-slate-50 px-4 py-2 text-sm text-slate-700 sm:w-auto">
                  <span className="sr-only">Active store</span>
                  <select
                    value={activeMarketplaceId ?? adminContext.marketplaces[0].id}
                    onChange={(e) => setActiveMarketplaceId(Number(e.target.value))}
                    className="w-full bg-transparent text-sm outline-none sm:min-w-[11rem]"
                  >
                    {adminContext.marketplaces.map((mkt) => (
                      <option key={mkt.id} value={mkt.id}>
                        {mkt.name}
                      </option>
                    ))}
                  </select>
                </label>
              ) : (
                <div className="w-full rounded-full border border-slate-200 bg-slate-50 px-4 py-2 text-sm text-slate-700 sm:w-auto">
                  {storeName}
                </div>
              )}
              <div className="w-full truncate rounded-full border border-slate-200 bg-slate-50 px-4 py-2 text-sm text-slate-700 sm:w-auto sm:max-w-[18rem]">
                {session?.user?.name ?? session?.user?.email ?? "Loading user"}
              </div>
              <LogoutButton />
            </div>
          </header>

          <main className="flex-1 px-4 py-4 sm:px-6 sm:py-6">{children}</main>
        </div>
      </div>

      {mobileOpen ? (
        <div className="fixed inset-0 z-50 flex lg:hidden">
          <button
            type="button"
            aria-label="Close navigation"
            className="absolute inset-0 bg-slate-950/40"
            onClick={() => setMobileOpen(false)}
          />
          <div className="relative z-10 h-full w-[min(20rem,88vw)] bg-slate-950 p-6 text-slate-100 shadow-2xl">
            <div className="flex items-center justify-between">
              <p className="text-sm font-semibold">{orgName}</p>
              <button
                type="button"
                className="rounded-xl border border-white/15 bg-white/5 px-3 py-2 text-sm font-medium text-white hover:bg-white/10"
                onClick={() => setMobileOpen(false)}
              >
                Close
              </button>
            </div>
            <nav className="mt-6 flex flex-col gap-2">
              {visibleNavItems.map((item) => {
                const active = pathname === item.href || pathname.startsWith(`${item.href}/`);
                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    onClick={() => setMobileOpen(false)}
                    className={cn(
                      "rounded-2xl px-4 py-3 text-sm font-medium transition",
                      active ? "bg-white text-slate-950" : "text-slate-200 hover:bg-white/10 hover:text-white",
                    )}
                  >
                    {item.label}
                  </Link>
                );
              })}
            </nav>
            <button
              type="button"
              onClick={() => {
                setMobileOpen(false);
                startTour();
              }}
              className="mt-6 w-full rounded-2xl border border-white/15 bg-white/5 px-4 py-3 text-left text-sm font-medium text-white hover:bg-white/10"
            >
              Take a Tour
            </button>
          </div>
        </div>
      ) : null}
    </div>
  );
}
