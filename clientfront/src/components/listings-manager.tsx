"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { clientApiFetch } from "@/lib/client-api";
import type { Listing, PaginatedResponse } from "@/lib/types";

export default function ListingsManager() {
  const [page, setPage] = useState(1);
  const [payload, setPayload] = useState<PaginatedResponse<Listing> | null>(null);

  useEffect(() => {
    clientApiFetch<PaginatedResponse<Listing>>(`/v1/listings?page=${page}&per_page=12`)
      .then(setPayload)
      .catch(() => setPayload({ data: [], meta: { page, per_page: 12, total_count: 0, total_pages: 1 } }));
  }, [page]);

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-xs uppercase tracking-[0.25em] text-stone-500">Marketplace inventory</p>
          <h1 className="mt-2 text-2xl font-semibold tracking-tight text-stone-950">Listings</h1>
        </div>
        <Link href="/listings/new" className="rounded-full bg-stone-950 px-5 py-3 text-sm font-medium text-white">
          New listing
        </Link>
      </div>

      <div className="overflow-hidden rounded-[1.75rem] border border-stone-200 bg-white">
        <table className="min-w-full divide-y divide-stone-200 text-left text-sm">
          <thead className="bg-stone-50 text-stone-500">
            <tr>
              <th className="px-4 py-3 font-medium">Product</th>
              <th className="px-4 py-3 font-medium">Variant</th>
              <th className="px-4 py-3 font-medium">Status</th>
              <th className="px-4 py-3 font-medium">Price</th>
              <th className="px-4 py-3 font-medium">Updated</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-stone-100 bg-white">
            {(payload?.data ?? []).map((listing) => (
              <tr key={listing.id}>
                <td className="px-4 py-3">
                  <p className="font-medium text-stone-900">{listing.product.name}</p>
                  <p className="text-xs text-stone-500">{listing.product.sku}</p>
                </td>
                <td className="px-4 py-3 text-stone-600">{listing.variant.name}</td>
                <td className="px-4 py-3 text-stone-600">{listing.status ?? "active"}</td>
                <td className="px-4 py-3 text-stone-900">
                  {listing.price_cents ? `${listing.currency ?? "USD"} ${(listing.price_cents / 100).toFixed(2)}` : "Not set"}
                </td>
                <td className="px-4 py-3 text-stone-500">
                  {new Date(listing.updated_at).toLocaleString()}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="flex items-center justify-between">
        <button
          type="button"
          disabled={page <= 1}
          onClick={() => setPage((current) => Math.max(current - 1, 1))}
          className="rounded-full border border-stone-300 px-4 py-2 text-sm font-medium text-stone-700 disabled:opacity-50"
        >
          Previous
        </button>
        <p className="text-sm text-stone-500">
          Page {payload?.meta.page ?? page} of {payload?.meta.total_pages ?? 1}
        </p>
        <button
          type="button"
          disabled={page >= (payload?.meta.total_pages ?? 1)}
          onClick={() => setPage((current) => current + 1)}
          className="rounded-full border border-stone-300 px-4 py-2 text-sm font-medium text-stone-700 disabled:opacity-50"
        >
          Next
        </button>
      </div>
    </div>
  );
}

