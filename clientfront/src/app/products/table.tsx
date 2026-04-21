"use client";

import { useEffect, useState } from "react";
import { clientApiFetch } from "@/lib/client-api";
import { formatInrFromCents } from "@/lib/currency";
import type { Listing, PaginatedResponse } from "@/lib/types";

export default function ProductsTable() {
  const [query, setQuery] = useState("");
  const [page, setPage] = useState(1);
  const [data, setData] = useState<PaginatedResponse<Listing> | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let active = true;
    setLoading(true);

    const timer = window.setTimeout(() => {
      const params = new URLSearchParams({ page: String(page), per_page: "9" });
      if (query.trim()) params.set("q", query.trim());

      clientApiFetch<PaginatedResponse<Listing>>(`/v1/listings?${params.toString()}`)
        .then((payload) => {
          if (active) setData(payload);
        })
        .catch(() => {
          if (active) setData({ data: [], meta: { page, per_page: 9, total_count: 0, total_pages: 1 } });
        })
        .finally(() => {
          if (active) setLoading(false);
        });
    }, 250);

    return () => {
      active = false;
      window.clearTimeout(timer);
    };
  }, [page, query]);

  return (
    <section className="space-y-6">
      <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <input
          value={query}
          onChange={(event) => {
            setPage(1);
            setQuery(event.target.value);
          }}
          placeholder="Search products, SKU, or category"
          className="w-full rounded-2xl border border-stone-200 bg-white px-4 py-3 text-sm outline-none ring-0 transition focus:border-stone-900 md:max-w-md"
        />
        <p className="text-sm text-stone-500">
          {loading ? "Refreshing..." : `${data?.meta.total_count ?? 0} tenant listings`}
        </p>
      </div>

      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        {(data?.data ?? []).map((listing) => (
          <article
            key={listing.id}
            className="overflow-hidden rounded-[1.75rem] border border-stone-900/10 bg-white shadow-[0_18px_60px_rgba(80,57,24,0.08)]"
          >
            <div className="h-44 bg-[radial-gradient(circle_at_top,_rgba(235,94,40,0.22),_transparent_36%),linear-gradient(135deg,_#efe8da_0%,_#f8f4ed_100%)]" />
            <div className="space-y-4 p-5">
              <div className="flex items-start justify-between gap-3">
                <div>
                  <h2 className="text-lg font-semibold text-stone-900">{listing.product.name}</h2>
                  <p className="mt-1 text-sm text-stone-500">{listing.variant.name}</p>
                </div>
                <span className="rounded-full bg-stone-900 px-3 py-1 text-xs font-medium uppercase tracking-[0.2em] text-stone-50">
                  {listing.status ?? "active"}
                </span>
              </div>
              <div className="grid grid-cols-2 gap-3 text-sm text-stone-600">
                <div>
                  <p className="text-xs uppercase tracking-[0.2em] text-stone-400">Category</p>
                  <p className="mt-1">{listing.product.category.name}</p>
                </div>
                <div>
                  <p className="text-xs uppercase tracking-[0.2em] text-stone-400">Price</p>
                  <p className="mt-1 font-medium text-stone-900">
                    {formatInrFromCents(listing.price_cents)}
                  </p>
                </div>
              </div>
            </div>
          </article>
        ))}
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
          Page {data?.meta.page ?? page} of {data?.meta.total_pages ?? 1}
        </p>
        <button
          type="button"
          disabled={page >= (data?.meta.total_pages ?? 1)}
          onClick={() => setPage((current) => current + 1)}
          className="rounded-full border border-stone-300 px-4 py-2 text-sm font-medium text-stone-700 disabled:opacity-50"
        >
          Next
        </button>
      </div>
    </section>
  );
}
