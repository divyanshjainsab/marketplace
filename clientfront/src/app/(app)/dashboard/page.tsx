import { Suspense } from "react";
import DashboardView from "@/components/dashboard-view";

export default function DashboardPage() {
  return (
    <Suspense fallback={<p className="rounded-2xl bg-stone-100 px-4 py-6 text-sm text-stone-600">Loading dashboard…</p>}>
      <DashboardView />
    </Suspense>
  );
}
