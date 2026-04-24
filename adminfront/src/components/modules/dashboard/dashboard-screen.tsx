"use client";

import useSWR from "swr";
import { clientApiFetch } from "@/lib/client-api";
import type { DashboardResponse } from "@/lib/types";
import { useWorkspace } from "@/components/providers/workspace-provider";
import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";

function formatCount(value: number) {
  return new Intl.NumberFormat(undefined, { maximumFractionDigits: 0 }).format(value);
}

export function DashboardScreen() {
  const { loading: workspaceLoading, activeMarketplaceId, activeMarketplace } = useWorkspace();

  const dashboardSwr = useSWR<DashboardResponse>(
    activeMarketplaceId ? `/v1/admin/dashboard?marketplace_id=${activeMarketplaceId}` : null,
    (path: string) => clientApiFetch<DashboardResponse>(path),
  );

  const payload = dashboardSwr.data?.data ?? null;
  const loading = workspaceLoading || dashboardSwr.isLoading;

  return (
    <div className="space-y-6" data-tour="dashboard">
      <Card className="flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.3em] text-slate-500">Dashboard</p>
          <h1 className="mt-3 text-2xl font-semibold tracking-tight text-slate-950">
            {loading ? "Loading your workspace…" : payload?.organization?.name ?? "Organization"}
          </h1>
          <p className="mt-2 text-sm text-slate-600">
            {loading ? "Fetching organization-scoped stats." : `This is your store: ${payload?.marketplace?.name ?? activeMarketplace?.name ?? "Store"}.`}
          </p>
        </div>
        <div className="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-700">
          <p className="text-xs uppercase tracking-[0.25em] text-slate-500">Marketplace</p>
          {loading ? (
            <div className="mt-2 space-y-2">
              <Skeleton className="h-4 w-40" />
              <Skeleton className="h-4 w-56" />
            </div>
          ) : (
            <div className="mt-2 space-y-1">
              <p className="font-semibold">{payload?.marketplace_status?.name ?? payload?.marketplace?.name}</p>
              <p className="text-xs text-slate-500">
                {payload?.marketplace_status?.custom_domain ?? payload?.marketplace?.custom_domain ?? "—"}
              </p>
            </div>
          )}
        </div>
      </Card>

      {dashboardSwr.error ? (
        <Card className="border-rose-200 bg-rose-50 text-rose-900">
          <p className="text-sm font-semibold">Unable to load dashboard.</p>
          <p className="mt-2 text-sm">Check your session and try again.</p>
        </Card>
      ) : null}

      <section className="grid gap-4 md:grid-cols-2 lg:grid-cols-3" data-tour="dashboard-widgets">
        <Card className="bg-slate-50">
          <p className="text-xs font-semibold uppercase tracking-[0.25em] text-slate-500">Total products</p>
          <div className="mt-4 text-3xl font-semibold text-slate-950">
            {loading ? <Skeleton className="h-9 w-20" /> : formatCount(payload?.totals.products ?? 0)}
          </div>
        </Card>
        <Card className="bg-slate-50">
          <p className="text-xs font-semibold uppercase tracking-[0.25em] text-slate-500">Total listings</p>
          <div className="mt-4 text-3xl font-semibold text-slate-950">
            {loading ? <Skeleton className="h-9 w-20" /> : formatCount(payload?.totals.listings ?? 0)}
          </div>
        </Card>
        <Card className="bg-slate-50">
          <p className="text-xs font-semibold uppercase tracking-[0.25em] text-slate-500">Marketplace health</p>
          <div className="mt-4 space-y-2">
            {loading ? (
              <div className="space-y-2">
                <Skeleton className="h-4 w-40" />
                <Skeleton className="h-4 w-56" />
              </div>
            ) : payload?.listing_status_distribution?.length ? (
              payload.listing_status_distribution.map((row) => (
                <div key={row.status} className="flex items-center justify-between text-sm">
                  <span className="text-slate-700">{row.status}</span>
                  <span className="font-semibold text-slate-950">{formatCount(row.listing_count)}</span>
                </div>
              ))
            ) : (
              <p className="text-sm text-slate-600">No listing data yet.</p>
            )}
          </div>
        </Card>
        <Card className="bg-slate-50 lg:col-span-2">
          <p className="text-xs font-semibold uppercase tracking-[0.25em] text-slate-500">Category distribution</p>
          <div className="mt-4 space-y-2">
            {loading ? (
              <div className="space-y-2">
                <Skeleton className="h-4 w-full" />
                <Skeleton className="h-4 w-2/3" />
                <Skeleton className="h-4 w-1/2" />
              </div>
            ) : payload?.category_distribution?.length ? (
              payload.category_distribution.slice(0, 6).map((row) => (
                <div key={row.category.id} className="flex items-center justify-between text-sm">
                  <span className="text-slate-700">{row.category.name}</span>
                  <span className="font-semibold text-slate-950">{formatCount(row.product_count)}</span>
                </div>
              ))
            ) : (
              <p className="text-sm text-slate-600">No products categorized yet.</p>
            )}
          </div>
        </Card>

        <Card className="bg-slate-50">
          <p className="text-xs font-semibold uppercase tracking-[0.25em] text-slate-500">Product types</p>
          <div className="mt-4 space-y-2">
            {loading ? (
              <div className="space-y-2">
                <Skeleton className="h-4 w-full" />
                <Skeleton className="h-4 w-2/3" />
              </div>
            ) : payload?.product_type_distribution?.length ? (
              payload.product_type_distribution.slice(0, 6).map((row) => (
                <div key={row.product_type.id} className="flex items-center justify-between text-sm">
                  <span className="text-slate-700">{row.product_type.name}</span>
                  <span className="font-semibold text-slate-950">{formatCount(row.product_count)}</span>
                </div>
              ))
            ) : (
              <p className="text-sm text-slate-600">No product types yet.</p>
            )}
          </div>
        </Card>
      </section>

      <Card>
        <p className="text-xs font-semibold uppercase tracking-[0.25em] text-slate-500">Recent activity</p>
        <div className="mt-4 space-y-3">
          {loading ? (
            <div className="space-y-2">
              <Skeleton className="h-4 w-3/4" />
              <Skeleton className="h-4 w-2/3" />
              <Skeleton className="h-4 w-1/2" />
            </div>
          ) : payload?.recent_activity?.length ? (
            payload.recent_activity.map((event) => (
              <div key={`${event.type}:${event.id}`} className="flex flex-col gap-1 rounded-2xl border border-slate-200 bg-white px-4 py-3">
                <p className="text-sm font-semibold text-slate-900">{event.label}</p>
                <p className="text-xs text-slate-500">
                  {event.status ? `Status: ${event.status} · ` : ""}
                  {new Date(event.updated_at).toLocaleString()}
                </p>
              </div>
            ))
          ) : (
            <p className="text-sm text-slate-600">No activity yet.</p>
          )}
        </div>
      </Card>
    </div>
  );
}
