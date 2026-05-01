"use client";

import { useMemo, useState } from "react";
import useSWR from "swr";
import { clientApiFetch } from "@/lib/client-api";
import type { PaginatedResponse, Product } from "@/lib/types";
import { CloudinaryImage } from "@/components/media/cloudinary-image";
import { useWorkspace } from "@/components/providers/workspace-provider";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";

export function ProductsScreen() {
  const { activeMarketplaceId, activeMarketplace, loading: workspaceLoading } = useWorkspace();
  const [page, setPage] = useState(1);

  const key = useMemo(() => {
    if (!activeMarketplaceId) return null;
    const params = new URLSearchParams();
    params.set("marketplace_id", String(activeMarketplaceId));
    params.set("page", String(page));
    params.set("per_page", "20");
    return `/v1/admin/products?${params.toString()}`;
  }, [activeMarketplaceId, page]);

  const productsSwr = useSWR<PaginatedResponse<Product>>(key, (path: string) => clientApiFetch<PaginatedResponse<Product>>(path));
  const payload = productsSwr.data ?? null;
  const loading = workspaceLoading || productsSwr.isLoading;

  return (
    <div className="space-y-6">
      <Card className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <p className="text-xs uppercase tracking-[0.25em] text-slate-500">Catalog</p>
          <h1 className="mt-2 text-2xl font-semibold tracking-tight text-slate-950">Products</h1>
          <p className="mt-2 text-sm text-slate-600">
            {activeMarketplace?.name ? `Products with inventory in ${activeMarketplace.name}.` : "Products with inventory in your store."}
          </p>
        </div>
        <Button variant="secondary" onClick={() => productsSwr.mutate()} disabled={loading}>
          Refresh
        </Button>
      </Card>

      {productsSwr.error ? (
        <Card className="border-rose-200 bg-rose-50 text-rose-900">
          <p className="text-sm font-semibold">Unable to load products.</p>
        </Card>
      ) : null}

      <div className="overflow-hidden rounded-[1.75rem] border border-slate-200 bg-white">
        <table className="min-w-full divide-y divide-slate-200 text-left text-sm">
          <thead className="bg-slate-50 text-slate-500">
            <tr>
              <th className="px-4 py-3 font-medium">Product</th>
              <th className="px-4 py-3 font-medium">SKU</th>
              <th className="px-4 py-3 font-medium">Category</th>
              <th className="px-4 py-3 font-medium">Type</th>
              <th className="px-4 py-3 font-medium">Listings</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 bg-white">
            {loading ? (
              Array.from({ length: 8 }).map((_, idx) => (
                <tr key={idx}>
                  <td className="px-4 py-3">
                    <Skeleton className="h-4 w-56" />
                  </td>
                  <td className="px-4 py-3">
                    <Skeleton className="h-4 w-32" />
                  </td>
                  <td className="px-4 py-3">
                    <Skeleton className="h-4 w-28" />
                  </td>
                  <td className="px-4 py-3">
                    <Skeleton className="h-4 w-28" />
                  </td>
                  <td className="px-4 py-3">
                    <Skeleton className="h-4 w-10" />
                  </td>
                </tr>
              ))
            ) : (payload?.data ?? []).length ? (
              (payload?.data ?? []).map((product) => (
                <tr key={product.id}>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-3">
                      <CloudinaryImage
                        asset={product.image}
                        alt={product.name}
                        className="h-14 w-14 shrink-0"
                        sizes="56px"
                        fallbackLabel="No image"
                      />
                      <div>
                        <p className="font-medium text-slate-900">{product.name}</p>
                        <p className="text-xs text-slate-500">{product.image ? "Cloudinary-backed" : "No media yet"}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-4 py-3 text-slate-600">{product.sku}</td>
                  <td className="px-4 py-3 text-slate-600">{product.category?.name}</td>
                  <td className="px-4 py-3 text-slate-600">{product.product_type?.name}</td>
                  <td className="px-4 py-3 font-semibold text-slate-900">{product.listing_count ?? 0}</td>
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan={5} className="px-4 py-10 text-center text-sm text-slate-600">
                  No products found for this store.
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
