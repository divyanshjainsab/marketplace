"use client";

import type React from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useAuth } from "@/components/auth-provider";
import LogoutButton from "@/components/logout-button";

const NAV_ITEMS = [
  { href: "/dashboard", label: "Dashboard" },
  { href: "/users", label: "Users" },
  { href: "/orgs", label: "Organization" },
  { href: "/marketplaces", label: "Marketplaces" },
  { href: "/catalog", label: "Catalog" },
  { href: "/listings", label: "Listings" },
];

export default function AppShell({ children }: React.PropsWithChildren) {
  const pathname = usePathname();
  const { adminContext, orgSlug, session, loading } = useAuth();
  const base = orgSlug ? `/${orgSlug}` : "";

  return (
    <div className="min-h-screen bg-[radial-gradient(circle_at_top,_rgba(15,23,42,0.08),_transparent_40%),linear-gradient(180deg,_#fbfbfe_0%,_#f1f5f9_55%,_#eef2ff_100%)] text-slate-900">
      <div className="mx-auto flex min-h-screen max-w-[1600px] gap-6 px-4 py-4 lg:px-6">
        <aside className="hidden w-72 shrink-0 flex-col rounded-[2rem] border border-slate-900/10 bg-slate-950 px-5 py-6 text-slate-100 shadow-[0_24px_80px_rgba(15,23,42,0.22)] lg:flex">
          <div>
            <p className="text-xs uppercase tracking-[0.35em] text-slate-400">Admin</p>
            <h1 className="mt-3 text-2xl font-semibold">Control Plane</h1>
            <p className="mt-2 text-sm text-slate-400">
              {loading ? "Refreshing session..." : session?.user?.email ?? "Signed in"}
            </p>
            {adminContext?.organization ? (
              <p className="mt-3 text-sm text-slate-300">
                Org: <span className="font-semibold text-white">{adminContext.organization.name}</span>
              </p>
            ) : null}
          </div>
          <nav className="mt-10 flex flex-1 flex-col gap-2">
            {NAV_ITEMS.map((item) => {
              const href = `${base}${item.href}`;
              const active = pathname === href || pathname.startsWith(`${href}/`);
              return (
                <Link
                  key={item.href}
                  href={href}
                  className={`rounded-2xl px-4 py-3 text-sm font-medium transition ${
                    active
                      ? "bg-white text-slate-950"
                      : "text-slate-300 hover:bg-white/10 hover:text-white"
                  }`}
                >
                  {item.label}
                </Link>
              );
            })}
          </nav>
          <div className="rounded-3xl border border-white/10 bg-white/5 p-4">
            <p className="text-xs uppercase tracking-[0.25em] text-slate-500">Access</p>
            <p className="mt-2 text-sm text-slate-300">
              {session?.user?.roles?.includes("admin") ? "Admin" : "Limited"}
            </p>
          </div>
        </aside>

        <div className="flex min-h-full flex-1 flex-col rounded-[2rem] border border-slate-900/10 bg-white/80 shadow-[0_24px_80px_rgba(15,23,42,0.12)] backdrop-blur">
          <header className="flex flex-col gap-4 border-b border-slate-900/10 px-6 py-5 md:flex-row md:items-center md:justify-between">
            <div>
              <p className="text-xs uppercase tracking-[0.3em] text-slate-500">Administration</p>
              <h2 className="mt-2 text-2xl font-semibold tracking-tight">
                {adminContext?.organization?.name ?? "Marketplace platform"}
              </h2>
            </div>
            <div className="flex items-center gap-3">
              {adminContext?.marketplaces?.[0] ? (
                <div className="rounded-full border border-slate-200 bg-slate-50 px-4 py-2 text-sm text-slate-700">
                  {adminContext.marketplaces[0].name}
                </div>
              ) : null}
              <div className="rounded-full border border-slate-200 bg-slate-50 px-4 py-2 text-sm text-slate-700">
                {session?.user?.name ?? session?.user?.email ?? "Loading user"}
              </div>
              <LogoutButton />
            </div>
          </header>
          <main className="flex-1 px-6 py-6">{children}</main>
        </div>
      </div>
    </div>
  );
}
