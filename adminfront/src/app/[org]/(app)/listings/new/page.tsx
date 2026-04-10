import { Suspense } from "react";
import CreateListingForm from "@/components/create-listing-form";

export default function NewListingPage() {
  return (
    <Suspense fallback={<p className="rounded-2xl bg-slate-100 px-4 py-6 text-sm text-slate-600">Loading form…</p>}>
      <CreateListingForm />
    </Suspense>
  );
}

