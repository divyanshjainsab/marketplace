import { Suspense } from "react";
import ListingsManager from "@/components/listings-manager";

export default function ListingsPage() {
  return (
    <Suspense fallback={<p className="rounded-2xl bg-slate-100 px-4 py-6 text-sm text-slate-600">Loading listings…</p>}>
      <ListingsManager />
    </Suspense>
  );
}

