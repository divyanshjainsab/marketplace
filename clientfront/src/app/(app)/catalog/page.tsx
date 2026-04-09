import { Suspense } from "react";
import CatalogManager from "@/components/catalog-manager";

export default function CatalogPage() {
  return (
    <Suspense fallback={<p className="rounded-2xl bg-stone-100 px-4 py-6 text-sm text-stone-600">Loading catalog…</p>}>
      <CatalogManager />
    </Suspense>
  );
}

