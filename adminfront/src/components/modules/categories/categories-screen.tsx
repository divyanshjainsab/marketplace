"use client";

import { useMemo, useState } from "react";
import useSWR from "swr";
import { clientApiFetch } from "@/lib/client-api";
import type { Category, PaginatedResponse } from "@/lib/types";
import { useWorkspace } from "@/components/providers/workspace-provider";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";

export function CategoriesScreen() {
  const { activeMarketplaceId, activeMarketplace, loading: workspaceLoading } = useWorkspace();
  const [page, setPage] = useState(1);

  const key = useMemo(() => {
    if (!activeMarketplaceId) return null;
    const params = new URLSearchParams();
    params.set("marketplace_id", String(activeMarketplaceId));
    params.set("page", String(page));
    params.set("per_page", "50");
    return `/v1/admin/categories?${params.toString()}`;
  }, [activeMarketplaceId, page]);

  const categoriesSwr = useSWR<PaginatedResponse<Category>>(key, (path: string) => clientApiFetch<PaginatedResponse<Category>>(path));
  const payload = categoriesSwr.data ?? null;
  const loading = workspaceLoading || categoriesSwr.isLoading;

  return (
    <div className="space-y-5">
      <Card className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <p className="text-xs uppercase tracking-[0.25em] text-slate-500">Catalog</p>
          <h1 className="mt-2 text-2xl font-semibold tracking-tight text-slate-950">Categories</h1>
          <p className="mt-2 text-sm text-slate-600">
            {activeMarketplace?.name ? `Category coverage for ${activeMarketplace.name}.` : "Category coverage for your store."}
          </p>
        </div>
        <Button variant="secondary" onClick={() => categoriesSwr.mutate()} disabled={loading}>
          Refresh
        </Button>
      </Card>

      {categoriesSwr.error ? (
        <Card className="border-rose-200 bg-rose-50 text-rose-900">
          <p className="text-sm font-semibold">Unable to load categories.</p>
        </Card>
      ) : null}

      <div className="overflow-hidden rounded-[1.75rem] border border-slate-200 bg-white">
        <table className="min-w-full divide-y divide-slate-200 text-left text-sm">
          <thead className="bg-slate-50 text-slate-500">
            <tr>
              <th className="px-4 py-3 font-medium">Name</th>
              <th className="px-4 py-3 font-medium">Code</th>
              <th className="px-4 py-3 font-medium">Products</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 bg-white">
            {loading ? (
              Array.from({ length: 8 }).map((_, idx) => (
                <tr key={idx}>
                  <td className="px-4 py-3">
                    <Skeleton className="h-4 w-48" />
                  </td>
                  <td className="px-4 py-3">
                    <Skeleton className="h-4 w-32" />
                  </td>
                  <td className="px-4 py-3">
                    <Skeleton className="h-4 w-16" />
                  </td>
                </tr>
              ))
            ) : (payload?.data ?? []).length ? (
              (payload?.data ?? []).map((category) => (
                <tr key={category.id}>
                  <td className="px-4 py-3 font-medium text-slate-900">{category.name}</td>
                  <td className="px-4 py-3 text-slate-600">{category.code}</td>
                  <td className="px-4 py-3 font-semibold text-slate-900">{category.product_count ?? 0}</td>
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan={3} className="px-4 py-10 text-center text-sm text-slate-600">
                  No categories found for this store.
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
