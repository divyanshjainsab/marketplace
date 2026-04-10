"use client";

import { useMemo, useState } from "react";
import useSWR from "swr";
import { clientApiFetch } from "@/lib/client-api";
import type { Listing, PaginatedResponse } from "@/lib/types";
import { useWorkspace } from "@/components/providers/workspace-provider";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";

function formatMoney(priceCents: number | null, currency: string | null) {
  if (!priceCents) return "Not set";
  const value = priceCents / 100;
  return new Intl.NumberFormat(undefined, { style: "currency", currency: currency ?? "USD" }).format(value);
}

export function ListingsScreen() {
  const { activeMarketplaceId, activeMarketplace, loading: workspaceLoading } = useWorkspace();
  const [page, setPage] = useState(1);

  const key = useMemo(() => {
    if (!activeMarketplaceId) return null;
    const params = new URLSearchParams();
    params.set("marketplace_id", String(activeMarketplaceId));
    params.set("page", String(page));
    params.set("per_page", "12");
    return `/v1/admin/listings?${params.toString()}`;
  }, [activeMarketplaceId, page]);

  const listingsSwr = useSWR<PaginatedResponse<Listing>>(key, (path: string) => clientApiFetch<PaginatedResponse<Listing>>(path));
  const payload = listingsSwr.data ?? null;
  const loading = workspaceLoading || listingsSwr.isLoading;

  return (
    <div className="space-y-5" data-tour="listings">
      <Card className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <p className="text-xs uppercase tracking-[0.25em] text-slate-500">Store inventory</p>
          <h1 className="mt-2 text-2xl font-semibold tracking-tight text-slate-950">Listings</h1>
          <p className="mt-2 text-sm text-slate-600">
            {activeMarketplace?.name ? `${activeMarketplace.name} listings and pricing.` : "Organization-scoped listings and pricing."}
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="secondary" onClick={() => listingsSwr.mutate()} disabled={loading}>
            Refresh
          </Button>
        </div>
      </Card>

      {listingsSwr.error ? (
        <Card className="border-rose-200 bg-rose-50 text-rose-900">
          <p className="text-sm font-semibold">Unable to load listings.</p>
        </Card>
      ) : null}

      <div className="overflow-hidden rounded-[1.75rem] border border-slate-200 bg-white">
        <table className="min-w-full divide-y divide-slate-200 text-left text-sm">
          <thead className="bg-slate-50 text-slate-500">
            <tr>
              <th className="px-4 py-3 font-medium">Product</th>
              <th className="px-4 py-3 font-medium">Variant</th>
              <th className="px-4 py-3 font-medium">Status</th>
              <th className="px-4 py-3 font-medium">Price</th>
              <th className="px-4 py-3 font-medium">Updated</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 bg-white">
            {loading ? (
              Array.from({ length: 6 }).map((_, idx) => (
                <tr key={idx}>
                  <td className="px-4 py-3">
                    <Skeleton className="h-4 w-48" />
                    <Skeleton className="mt-2 h-3 w-28" />
                  </td>
                  <td className="px-4 py-3">
                    <Skeleton className="h-4 w-32" />
                  </td>
                  <td className="px-4 py-3">
                    <Skeleton className="h-4 w-20" />
                  </td>
                  <td className="px-4 py-3">
                    <Skeleton className="h-4 w-24" />
                  </td>
                  <td className="px-4 py-3">
                    <Skeleton className="h-4 w-36" />
                  </td>
                </tr>
              ))
            ) : (payload?.data ?? []).length ? (
              (payload?.data ?? []).map((listing) => (
                <tr key={listing.id}>
                  <td className="px-4 py-3">
                    <p className="font-medium text-slate-900">{listing.product.name}</p>
                    <p className="text-xs text-slate-500">{listing.product.sku}</p>
                  </td>
                  <td className="px-4 py-3 text-slate-600">{listing.variant.name}</td>
                  <td className="px-4 py-3 text-slate-600">{listing.status ?? "active"}</td>
                  <td className="px-4 py-3 font-medium text-slate-900">
                    {formatMoney(listing.price_cents, listing.currency)}
                  </td>
                  <td className="px-4 py-3 text-slate-500">{new Date(listing.updated_at).toLocaleString()}</td>
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan={5} className="px-4 py-10 text-center text-sm text-slate-600">
                  No listings found for this store.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      <div className="flex items-center justify-between">
        <Button variant="secondary" onClick={() => setPage((current) => Math.max(current - 1, 1))} disabled={page <= 1 || loading}>
          Previous
        </Button>
        <p className="text-sm text-slate-500">
          Page {payload?.meta.page ?? page} of {payload?.meta.total_pages ?? 1}
        </p>
        <Button
          variant="secondary"
          onClick={() => setPage((current) => current + 1)}
          disabled={loading || page >= (payload?.meta.total_pages ?? 1)}
        >
          Next
        </Button>
      </div>
    </div>
  );
}
