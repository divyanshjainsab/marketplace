import { Suspense } from "react";
import MarketplacesView from "@/components/marketplaces-view";

export default function MarketplacesPage() {
  return (
    <Suspense fallback={<p className="rounded-2xl bg-slate-100 px-4 py-6 text-sm text-slate-600">Loading marketplaces...</p>}>
      <MarketplacesView />
    </Suspense>
  );
}
