"use client";

import { useEffect, useState } from "react";
import { clientApiFetch } from "@/lib/client-api";

type PaginatedResponse<T> = {
  data: T[];
  meta: { page: number; per_page: number; total_count: number; total_pages: number };
};

type Marketplace = {
  id: number;
  name: string;
  subdomain: string;
  organization_id: number;
};

export default function MarketplacesView() {
  const [payload, setPayload] = useState<PaginatedResponse<Marketplace> | null>(null);

  useEffect(() => {
    clientApiFetch<PaginatedResponse<Marketplace>>("/v1/admin/marketplaces?per_page=50")
      .then(setPayload)
      .catch(() => setPayload({ data: [], meta: { page: 1, per_page: 50, total_count: 0, total_pages: 1 } }));
  }, []);

  return (
    <div className="rounded-[1.75rem] border border-slate-900/10 bg-white p-6">
      <p className="text-xs font-semibold uppercase tracking-[0.3em] text-slate-500">Platform</p>
      <h1 className="mt-3 text-2xl font-semibold tracking-tight text-slate-950">Marketplaces</h1>
      <p className="mt-2 text-sm text-slate-600">{payload ? `${payload.meta.total_count} total` : "Loading..."}</p>

      <div className="mt-6 overflow-hidden rounded-3xl border border-slate-200">
        <table className="min-w-full divide-y divide-slate-200 text-left text-sm">
          <thead className="bg-slate-50 text-slate-500">
            <tr>
              <th className="px-4 py-3 font-medium">Name</th>
              <th className="px-4 py-3 font-medium">Subdomain</th>
              <th className="px-4 py-3 font-medium">Org ID</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 bg-white">
            {(payload?.data ?? []).map((mkt) => (
              <tr key={mkt.id}>
                <td className="px-4 py-3 font-medium text-slate-900">{mkt.name}</td>
                <td className="px-4 py-3 text-slate-700">{mkt.subdomain}</td>
                <td className="px-4 py-3 text-slate-700">{mkt.organization_id}</td>
              </tr>
            ))}
            {payload && payload.data.length === 0 ? (
              <tr>
                <td className="px-4 py-8 text-center text-slate-500" colSpan={3}>
                  No marketplaces found.
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </div>
    </div>
  );
}

