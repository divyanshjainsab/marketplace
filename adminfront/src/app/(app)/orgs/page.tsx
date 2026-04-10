import { Suspense } from "react";
import OrganizationsView from "@/components/organizations-view";

export default function OrgsPage() {
  return (
    <Suspense fallback={<p className="rounded-2xl bg-slate-100 px-4 py-6 text-sm text-slate-600">Loading organizations...</p>}>
      <OrganizationsView />
    </Suspense>
  );
}
