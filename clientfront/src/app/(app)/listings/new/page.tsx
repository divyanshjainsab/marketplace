import { Suspense } from "react";
import CreateListingForm from "@/components/create-listing-form";

export default function NewListingPage() {
  return (
    <Suspense fallback={<p className="rounded-2xl bg-stone-100 px-4 py-6 text-sm text-stone-600">Loading create form…</p>}>
      <CreateListingForm />
    </Suspense>
  );
}
