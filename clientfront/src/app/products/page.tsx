import { Suspense } from "react";
import ProductsTable from "./table";

export default function ProductsPage() {
  return (
    <main className="min-h-screen bg-[linear-gradient(180deg,_#f8f3ea_0%,_#f0e5d4_100%)] px-4 py-8 text-stone-900 md:px-6">
      <div className="mx-auto max-w-7xl rounded-[2rem] border border-stone-900/10 bg-white/75 p-6 shadow-[0_24px_80px_rgba(83,58,21,0.12)] backdrop-blur md:p-8">
        <div className="mb-8 flex flex-col gap-3 md:flex-row md:items-end md:justify-between">
          <div>
            <p className="text-xs uppercase tracking-[0.3em] text-stone-500">Tenant Storefront</p>
            <h1 className="mt-2 text-4xl font-semibold tracking-tight">Marketplace products</h1>
            <p className="mt-3 max-w-2xl text-sm leading-6 text-stone-600">
              Public catalog browsing is tenant-aware and does not require login.
            </p>
          </div>
        </div>
        <Suspense fallback={<p className="rounded-2xl bg-stone-100 px-4 py-6 text-sm text-stone-600">Loading products…</p>}>
        <ProductsTable />
      </Suspense>
      </div>
    </main>
  );
}
