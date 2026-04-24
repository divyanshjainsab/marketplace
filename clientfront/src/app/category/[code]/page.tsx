import Link from "next/link";
import { apiFetch } from "@/lib/api";
import { CloudinaryImage } from "@/components/media/cloudinary-image";
import { formatInrFromCents } from "@/lib/currency";
import type { Category, Listing, PaginatedResponse } from "@/lib/types";

export const revalidate = 60;

export default async function CategoryPage({ params }: { params: { code: string } }) {
  const categoriesPayload = await apiFetch<PaginatedResponse<Category>>("/api/v1/categories?per_page=200", {
    next: { revalidate },
  });
  const category = categoriesPayload.data.find((row) => row.code === params.code) ?? null;
  if (!category) {
    return (
      <main className="px-4 py-8 md:px-6">
        <div className="mx-auto max-w-5xl rounded-[2rem] border border-stone-900/10 bg-white/75 p-6 shadow-[0_24px_80px_rgba(83,58,21,0.12)] backdrop-blur md:p-8">
          <p className="text-sm font-medium text-stone-900">Category not found.</p>
          <Link href="/products" className="mt-4 inline-flex text-sm font-semibold text-stone-700 hover:text-stone-900">
            Browse all products →
          </Link>
        </div>
      </main>
    );
  }

  const listingsPayload = await apiFetch<PaginatedResponse<Listing>>(
    `/api/v1/listings?category_id=${category.id}&per_page=24`,
    { next: { revalidate } },
  );

  return (
    <main className="px-4 py-8 md:px-6">
      <div className="mx-auto max-w-6xl rounded-[2rem] border border-stone-900/10 bg-white/75 p-6 shadow-[0_24px_80px_rgba(83,58,21,0.12)] backdrop-blur md:p-8">
        <div className="flex flex-col gap-2 md:flex-row md:items-end md:justify-between">
          <div>
            <p className="text-xs uppercase tracking-[0.3em] text-stone-500">Category</p>
            <h1 className="mt-2 text-3xl font-semibold tracking-tight md:text-4xl">{category.name}</h1>
            <p className="mt-2 text-sm text-stone-600">{listingsPayload.meta.total_count} listings</p>
          </div>
          <Link href="/products" className="text-sm font-semibold text-stone-700 hover:text-stone-900">
            Browse all →
          </Link>
        </div>

        <div className="mt-8 grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          {listingsPayload.data.map((listing) => (
            <Link
              key={listing.id}
              href={`/products/${listing.product.id}?variant_id=${listing.variant.id}`}
              className="overflow-hidden rounded-[1.75rem] border border-stone-900/10 bg-white shadow-[0_18px_60px_rgba(80,57,24,0.08)]"
            >
              <CloudinaryImage
                asset={listing.image}
                alt={listing.product.name}
                className="h-44 w-full"
                fill
                sizes="(min-width: 1280px) 24rem, (min-width: 768px) 40vw, 100vw"
                fallbackLabel="Listing image"
              />
              <div className="space-y-3 p-5">
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <h2 className="text-lg font-semibold text-stone-900">{listing.product.name}</h2>
                    <p className="mt-1 text-sm text-stone-500">{listing.variant.name}</p>
                  </div>
                  <span className="rounded-full bg-stone-900 px-3 py-1 text-xs font-medium uppercase tracking-[0.2em] text-stone-50">
                    {listing.status ?? "active"}
                  </span>
                </div>
                <div className="flex items-center justify-between text-sm">
                  <span className="text-stone-500">{listing.inventory_count > 0 ? "In stock" : "Out of stock"}</span>
                  <span className="font-semibold text-stone-900">{formatInrFromCents(listing.price_cents)}</span>
                </div>
              </div>
            </Link>
          ))}

          {listingsPayload.data.length === 0 ? (
            <p className="text-sm text-stone-600">No listings yet.</p>
          ) : null}
        </div>
      </div>
    </main>
  );
}

