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

export function ProductsScreenV2() {
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
    <div className="space-y-5">
      <Card className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
        <div>
          <p className="text-xs uppercase tracking-[0.25em] text-slate-500">Catalog</p>
          <h1 className="mt-2 text-2xl font-semibold tracking-tight text-slate-950">Products</h1>
          <p className="mt-2 text-sm text-slate-600">
            {activeMarketplace?.name ? `Products with inventory in ${activeMarketplace.name}.` : "Products with inventory in your store."}
          </p>
        </div>
        <Button variant="secondary" onClick={() => productsSwr.mutate()} disabled={loading}>
          Refresh products
        </Button>
      </Card>

      {productsSwr.error ? (
        <Card className="border-rose-200 bg-rose-50 text-rose-900">
          <p className="text-sm font-semibold">Unable to load products.</p>
        </Card>
      ) : null}

      <div className="grid gap-4">
        {loading ? (
          Array.from({ length: 6 }).map((_, idx) => <Skeleton key={idx} className="h-32 w-full rounded-[1.75rem]" />)
        ) : (payload?.data ?? []).length ? (
          (payload?.data ?? []).map((product) => (
            <Card key={product.id}>
              <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                <div className="flex min-w-0 items-start gap-4">
                  <CloudinaryImage
                    asset={product.image}
                    alt={product.name}
                    className="h-24 w-24 shrink-0"
                    sizes="96px"
                    fallbackLabel="No image"
                  />
                  <div className="min-w-0">
                    <p className="truncate text-lg font-semibold text-slate-950">{product.name}</p>
                    <p className="mt-1 text-sm text-slate-500">{product.sku}</p>
                    <div className="mt-3 grid gap-2 text-sm text-slate-600 sm:grid-cols-2">
                      <p>Category: {product.category?.name ?? "Not set"}</p>
                      <p>Type: {product.product_type?.name ?? "Not set"}</p>
                      <p>{product.image ? "Cloudinary-backed media" : "No media yet"}</p>
                      <p>{product.listing_count ?? 0} listings</p>
                    </div>
                  </div>
                </div>
              </div>
            </Card>
          ))
        ) : (
          <Card>
            <p className="text-center text-sm text-slate-600">No products found for this store.</p>
          </Card>
        )}
      </div>

      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
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
