"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import { usePathname } from "next/navigation";
import { clientApiFetch } from "@/lib/client-api";
import type { Listing, PaginatedResponse } from "@/lib/types";
import { useAuth } from "@/components/auth-provider";

function orgBaseFromPath(pathname: string): string {
  const segment = pathname.split("/")[1] ?? "";
  if (!segment) return "";
  if (segment === "api" || segment === "callback" || segment === "not-authorized") return "";
  return `/${segment}`;
}

export default function ListingsManager() {
  const pathname = usePathname();
  const base = orgBaseFromPath(pathname);
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
          <p className="text-xs uppercase tracking-[0.25em] text-slate-500">Marketplace inventory</p>
          <h1 className="mt-2 text-2xl font-semibold tracking-tight text-slate-950">Listings</h1>
        </div>
        <Link href={`${base}/listings/new`} className="rounded-full bg-slate-950 px-5 py-3 text-sm font-medium text-white">
          New listing
        </Link>
      </div>

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
            {(payload?.data ?? []).map((listing) => (
              <tr key={listing.id}>
                <td className="px-4 py-3">
                  <p className="font-medium text-slate-900">{listing.product.name}</p>
                  <p className="text-xs text-slate-500">{listing.product.sku}</p>
                </td>
                <td className="px-4 py-3 text-slate-600">{listing.variant.name}</td>
                <td className="px-4 py-3 text-slate-600">{listing.status ?? "active"}</td>
                <td className="px-4 py-3 text-slate-900">
                  {listing.price_cents ? `${listing.currency ?? "USD"} ${(listing.price_cents / 100).toFixed(2)}` : "Not set"}
                </td>
                <td className="px-4 py-3 text-slate-500">{new Date(listing.updated_at).toLocaleString()}</td>
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
          className="rounded-full border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 disabled:opacity-50"
        >
          Previous
        </button>
        <p className="text-sm text-slate-500">
          Page {payload?.meta.page ?? page} of {payload?.meta.total_pages ?? 1}
        </p>
        <button
          type="button"
          disabled={page >= (payload?.meta.total_pages ?? 1)}
          onClick={() => setPage((current) => current + 1)}
          className="rounded-full border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 disabled:opacity-50"
        >
          Next
        </button>
      </div>
    </div>
  );
}

