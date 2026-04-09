"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { clientApiFetch } from "@/lib/client-api";
import type { Category, Listing, PaginatedResponse, ProductType } from "@/lib/types";

type DashboardData = {
  listings: PaginatedResponse<Listing>;
  categories: PaginatedResponse<Category>;
  productTypes: PaginatedResponse<ProductType>;
};

export default function DashboardView() {
  const [data, setData] = useState<DashboardData | null>(null);

  useEffect(() => {
    Promise.all([
      clientApiFetch<PaginatedResponse<Listing>>("/v1/listings?per_page=5"),
      clientApiFetch<PaginatedResponse<Category>>("/v1/categories?per_page=100"),
      clientApiFetch<PaginatedResponse<ProductType>>("/v1/product_types?per_page=100"),
    ]).then(([listings, categories, productTypes]) => {
      setData({ listings, categories, productTypes });
    }).catch(() => {
      setData({
        listings: { data: [], meta: { page: 1, per_page: 5, total_count: 0, total_pages: 1 } },
        categories: { data: [], meta: { page: 1, per_page: 100, total_count: 0, total_pages: 1 } },
        productTypes: { data: [], meta: { page: 1, per_page: 100, total_count: 0, total_pages: 1 } },
      });
    });
  }, []);

  const cards = [
    { label: "Listings", value: data?.listings.meta.total_count ?? 0 },
    { label: "Categories", value: data?.categories.meta.total_count ?? 0 },
    { label: "Product types", value: data?.productTypes.meta.total_count ?? 0 },
  ];

  return (
    <div className="space-y-6">
      <section className="grid gap-4 md:grid-cols-3">
        {cards.map((card) => (
          <article key={card.label} className="rounded-[1.75rem] border border-stone-900/10 bg-stone-50 p-5">
            <p className="text-xs uppercase tracking-[0.25em] text-stone-500">{card.label}</p>
            <p className="mt-4 text-4xl font-semibold tracking-tight text-stone-950">{card.value}</p>
          </article>
        ))}
      </section>

      <section className="grid gap-6 xl:grid-cols-[1.3fr_0.9fr]">
        <article className="rounded-[1.75rem] border border-stone-900/10 bg-white p-5">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs uppercase tracking-[0.25em] text-stone-500">Recent listings</p>
              <h3 className="mt-2 text-xl font-semibold text-stone-950">Latest tenant updates</h3>
            </div>
            <Link href="/listings" className="text-sm font-medium text-stone-700 underline-offset-4 hover:underline">
              View all
            </Link>
          </div>
          <div className="mt-5 overflow-hidden rounded-3xl border border-stone-200">
            <table className="min-w-full divide-y divide-stone-200 text-left text-sm">
              <thead className="bg-stone-50 text-stone-500">
                <tr>
                  <th className="px-4 py-3 font-medium">Product</th>
                  <th className="px-4 py-3 font-medium">Variant</th>
                  <th className="px-4 py-3 font-medium">Status</th>
                  <th className="px-4 py-3 font-medium">Price</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-stone-100 bg-white">
                {(data?.listings.data ?? []).map((listing) => (
                  <tr key={listing.id}>
                    <td className="px-4 py-3 font-medium text-stone-900">{listing.product.name}</td>
                    <td className="px-4 py-3 text-stone-600">{listing.variant.name}</td>
                    <td className="px-4 py-3 text-stone-600">{listing.status ?? "active"}</td>
                    <td className="px-4 py-3 text-stone-900">
                      {listing.price_cents ? `${listing.currency ?? "USD"} ${(listing.price_cents / 100).toFixed(2)}` : "Not set"}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </article>

        <article className="rounded-[1.75rem] border border-stone-900/10 bg-[linear-gradient(180deg,_#15120d_0%,_#272017_100%)] p-5 text-stone-50">
          <p className="text-xs uppercase tracking-[0.25em] text-stone-400">Actions</p>
          <h3 className="mt-2 text-xl font-semibold">Keep the tenant catalog moving</h3>
          <div className="mt-5 space-y-3">
            <Link href="/listings/new" className="block rounded-2xl bg-white px-4 py-3 text-sm font-medium text-stone-950">
              Create a new listing
            </Link>
            <Link href="/catalog" className="block rounded-2xl border border-white/15 px-4 py-3 text-sm font-medium text-white">
              Review global products
            </Link>
            <Link href="/products" className="block rounded-2xl border border-white/15 px-4 py-3 text-sm font-medium text-white">
              Open public storefront
            </Link>
          </div>
        </article>
      </section>
    </div>
  );
}

