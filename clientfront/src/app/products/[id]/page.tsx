import { apiFetch } from "@/lib/api";
import type { Listing, PaginatedResponse, Product } from "@/lib/types";
import ProductDetail from "./product-detail";

export const revalidate = 30;

export default async function ProductDetailPage({
  params,
  searchParams,
}: {
  params: { id: string };
  searchParams?: Record<string, string | string[] | undefined>;
}) {
  const productId = Number(params.id);

  const productPayload = await apiFetch<{ data: Product }>(`/api/v1/products/${productId}`, {
    next: { revalidate },
  });

  const listingsPayload = await apiFetch<PaginatedResponse<Listing>>(
    `/api/v1/listings?product_id=${productId}&per_page=100`,
    { next: { revalidate } },
  );

  const initialVariantIdRaw = searchParams?.variant_id;
  const initialVariantId =
    typeof initialVariantIdRaw === "string" && initialVariantIdRaw.trim()
      ? Number(initialVariantIdRaw)
      : null;

  return (
    <main className="px-4 py-8 md:px-6">
      <div className="mx-auto max-w-6xl rounded-[2rem] border border-stone-900/10 bg-white/75 p-6 shadow-[0_24px_80px_rgba(83,58,21,0.12)] backdrop-blur md:p-8">
        <ProductDetail
          product={productPayload.data}
          listings={listingsPayload.data}
          initialVariantId={initialVariantId}
        />
      </div>
    </main>
  );
}

