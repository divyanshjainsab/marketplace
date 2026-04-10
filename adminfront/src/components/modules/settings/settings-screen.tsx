"use client";

import { useWorkspace } from "@/components/providers/workspace-provider";
import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";

export function SettingsScreen() {
  const { session, adminContext, activeMarketplace, loading } = useWorkspace();

  return (
    <div className="space-y-5">
      <Card>
        <p className="text-xs uppercase tracking-[0.25em] text-slate-500">Settings</p>
        <h1 className="mt-2 text-2xl font-semibold tracking-tight text-slate-950">Organization</h1>
        <p className="mt-2 text-sm text-slate-600">Admin access and marketplace configuration are scoped to your organization.</p>
      </Card>

      <section className="grid gap-4 md:grid-cols-2">
        <Card className="bg-slate-50">
          <p className="text-xs font-semibold uppercase tracking-[0.25em] text-slate-500">Organization</p>
          {loading ? (
            <div className="mt-3 space-y-2">
              <Skeleton className="h-4 w-48" />
              <Skeleton className="h-4 w-32" />
            </div>
          ) : (
            <div className="mt-3 space-y-1 text-sm text-slate-700">
              <p className="font-semibold text-slate-950">{adminContext?.organization?.name ?? session?.organization?.name}</p>
              <p className="text-xs text-slate-500">Slug: {adminContext?.organization?.slug ?? session?.organization?.slug}</p>
            </div>
          )}
        </Card>

        <Card className="bg-slate-50">
          <p className="text-xs font-semibold uppercase tracking-[0.25em] text-slate-500">Admin profile</p>
          {loading ? (
            <div className="mt-3 space-y-2">
              <Skeleton className="h-4 w-56" />
              <Skeleton className="h-4 w-40" />
            </div>
          ) : (
            <div className="mt-3 space-y-1 text-sm text-slate-700">
              <p className="font-semibold text-slate-950">{session?.user?.name ?? "Admin"}</p>
              <p className="text-xs text-slate-500">{session?.user?.email}</p>
              <p className="text-xs text-slate-500">Roles: {(session?.user?.roles ?? []).join(", ") || "none"}</p>
            </div>
          )}
        </Card>
      </section>

      <Card>
        <p className="text-xs font-semibold uppercase tracking-[0.25em] text-slate-500">Marketplaces</p>
        <div className="mt-4 overflow-hidden rounded-2xl border border-slate-200 bg-white">
          <table className="min-w-full divide-y divide-slate-200 text-left text-sm">
            <thead className="bg-slate-50 text-slate-500">
              <tr>
                <th className="px-4 py-3 font-medium">Name</th>
                <th className="px-4 py-3 font-medium">Subdomain</th>
                <th className="px-4 py-3 font-medium">Custom domain</th>
                <th className="px-4 py-3 font-medium">Active</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 bg-white">
              {loading ? (
                Array.from({ length: 3 }).map((_, idx) => (
                  <tr key={idx}>
                    <td className="px-4 py-3">
                      <Skeleton className="h-4 w-40" />
                    </td>
                    <td className="px-4 py-3">
                      <Skeleton className="h-4 w-24" />
                    </td>
                    <td className="px-4 py-3">
                      <Skeleton className="h-4 w-48" />
                    </td>
                    <td className="px-4 py-3">
                      <Skeleton className="h-4 w-10" />
                    </td>
                  </tr>
                ))
              ) : (adminContext?.marketplaces ?? []).length ? (
                adminContext!.marketplaces.map((mkt) => (
                  <tr key={mkt.id}>
                    <td className="px-4 py-3 font-medium text-slate-900">{mkt.name}</td>
                    <td className="px-4 py-3 text-slate-600">{mkt.subdomain}</td>
                    <td className="px-4 py-3 text-slate-600">{mkt.custom_domain ?? "—"}</td>
                    <td className="px-4 py-3 text-slate-600">{activeMarketplace?.id === mkt.id ? "Yes" : ""}</td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={4} className="px-4 py-10 text-center text-sm text-slate-600">
                    No marketplaces configured.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </Card>
    </div>
  );
}
