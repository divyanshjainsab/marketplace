"use client";

import { useMemo, useState } from "react";
import useSWR from "swr";
import { clientApiFetch } from "@/lib/client-api";
import type { PaginatedResponse, Product } from "@/lib/types";
import { CloudinaryImage } from "@/components/media/cloudinary-image";
import { useWorkspace } from "@/components/providers/workspace-provider";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { PageHeader } from "@/components/ui/page-header";
import { Skeleton } from "@/components/ui/skeleton";
import { Table, Td, Th, Tr } from "@/components/ui/table";

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
    <div className="space-y-6">
      <PageHeader
        kicker="Catalog"
        title="Products"
        description={
          activeMarketplace?.name
            ? `Products with inventory in ${activeMarketplace.name}.`
            : "Products with inventory in your store."
        }
        actions={
          <Button variant="secondary" onClick={() => productsSwr.mutate()} disabled={loading}>
            Refresh products
          </Button>
        }
      />

      {productsSwr.error ? (
        <Card className="border-rose-200 bg-rose-50 text-rose-900">
          <p className="text-sm font-semibold">Unable to load products.</p>
        </Card>
      ) : null}

      {loading ? (
        <Table className="min-w-[56rem]">
          <thead>
            <tr>
              <Th>Product</Th>
              <Th>Category</Th>
              <Th>Type</Th>
              <Th>Listings</Th>
              <Th>Media</Th>
            </tr>
          </thead>
          <tbody>
            {Array.from({ length: 8 }).map((_, idx) => (
              <Tr key={idx}>
                <Td>
                  <div className="flex items-center gap-3">
                    <Skeleton className="h-12 w-12" />
                    <div className="space-y-2">
                      <Skeleton className="h-4 w-56" />
                      <Skeleton className="h-3 w-32" />
                    </div>
                  </div>
                </Td>
                <Td>
                  <Skeleton className="h-4 w-36" />
                </Td>
                <Td>
                  <Skeleton className="h-4 w-36" />
                </Td>
                <Td>
                  <Skeleton className="h-4 w-16" />
                </Td>
                <Td>
                  <Skeleton className="h-4 w-32" />
                </Td>
              </Tr>
            ))}
          </tbody>
        </Table>
      ) : (payload?.data ?? []).length ? (
        <Table className="min-w-[56rem]">
          <thead>
            <tr>
              <Th>Product</Th>
              <Th>Category</Th>
              <Th>Type</Th>
              <Th>Listings</Th>
              <Th>Media</Th>
            </tr>
          </thead>
          <tbody>
            {(payload?.data ?? []).map((product) => (
              <Tr key={product.id}>
                <Td className="min-w-[18rem]">
                  <div className="flex min-w-0 items-center gap-3">
                    <CloudinaryImage
                      asset={product.image}
                      alt={product.name}
                      className="h-12 w-12 shrink-0"
                      sizes="48px"
                      fallbackLabel="No image"
                    />
                    <div className="min-w-0">
                      <p className="truncate font-semibold text-slate-950">{product.name}</p>
                      <p className="mt-1 text-xs font-semibold uppercase tracking-[0.18em] text-slate-500">{product.sku}</p>
                    </div>
                  </div>
                </Td>
                <Td className="whitespace-nowrap">{product.category?.name ?? "Not set"}</Td>
                <Td className="whitespace-nowrap">{product.product_type?.name ?? "Not set"}</Td>
                <Td className="whitespace-nowrap">{product.listing_count ?? 0}</Td>
                <Td className="whitespace-nowrap">{product.image ? "Cloudinary-backed" : "No media"}</Td>
              </Tr>
            ))}
          </tbody>
        </Table>
      ) : (
        <Card>
          <p className="text-center text-sm text-slate-600">No products found for this store.</p>
        </Card>
      )}

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
