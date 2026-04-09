"use client";

import type React from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useAuth } from "@/components/auth-provider";
import { useTenant } from "@/components/tenant-provider";
import LogoutButton from "@/components/logout-button";

const NAV_ITEMS = [
  { href: "/dashboard", label: "Dashboard" },
  { href: "/catalog", label: "Catalog" },
  { href: "/listings", label: "Listings" },
  { href: "/listings/new", label: "Create Listing" },
  { href: "/products", label: "Public Products" },
];

export default function AppShell({ children }: React.PropsWithChildren) {
  const pathname = usePathname();
  const { session, loading } = useAuth();
  const tenant = useTenant();

  return (
    <div className="min-h-screen bg-[linear-gradient(180deg,_#f5f1e7_0%,_#efe4d2_52%,_#e8dcc8_100%)] text-stone-900">
      <div className="mx-auto flex min-h-screen max-w-[1600px] gap-6 px-4 py-4 lg:px-6">
        <aside className="hidden w-72 shrink-0 flex-col rounded-[2rem] border border-stone-900/10 bg-stone-950 px-5 py-6 text-stone-100 shadow-[0_24px_80px_rgba(20,16,10,0.22)] lg:flex">
          <div>
            <p className="text-xs uppercase tracking-[0.35em] text-stone-400">Marketplace</p>
            <h1 className="mt-3 text-2xl font-semibold">Control Panel</h1>
            <p className="mt-2 text-sm text-stone-400">
              Tenant: <span className="text-stone-200">{tenant.subdomain ?? "default"}</span>
            </p>
          </div>
          <nav className="mt-10 flex flex-1 flex-col gap-2">
            {NAV_ITEMS.map((item) => {
              const active = pathname === item.href || pathname.startsWith(`${item.href}/`);
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={`rounded-2xl px-4 py-3 text-sm font-medium transition ${
                    active
                      ? "bg-stone-100 text-stone-950"
                      : "text-stone-300 hover:bg-white/10 hover:text-white"
                  }`}
                >
                  {item.label}
                </Link>
              );
            })}
          </nav>
          <div className="rounded-3xl border border-white/10 bg-white/5 p-4">
            <p className="text-xs uppercase tracking-[0.25em] text-stone-500">Session</p>
            <p className="mt-2 text-sm text-stone-300">
              {loading ? "Refreshing session..." : session?.user?.email ?? "Signed in"}
            </p>
          </div>
        </aside>

        <div className="flex min-h-full flex-1 flex-col rounded-[2rem] border border-stone-900/10 bg-white/80 shadow-[0_24px_80px_rgba(67,49,24,0.12)] backdrop-blur">
          <header className="flex flex-col gap-4 border-b border-stone-900/10 px-6 py-5 md:flex-row md:items-center md:justify-between">
            <div>
              <p className="text-xs uppercase tracking-[0.3em] text-stone-500">Operations</p>
              <h2 className="mt-2 text-2xl font-semibold tracking-tight">Multi-tenant inventory</h2>
            </div>
            <div className="flex items-center gap-3">
              <div className="rounded-full border border-stone-200 bg-stone-50 px-4 py-2 text-sm text-stone-700">
                {session?.marketplace?.name ?? "Tenant pending"}
              </div>
              <div className="rounded-full border border-stone-200 bg-stone-50 px-4 py-2 text-sm text-stone-700">
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
