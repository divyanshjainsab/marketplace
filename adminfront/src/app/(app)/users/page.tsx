import { Suspense } from "react";
import UsersView from "@/components/users-view";

export default function UsersPage() {
  return (
    <Suspense fallback={<p className="rounded-2xl bg-slate-100 px-4 py-6 text-sm text-slate-600">Loading users...</p>}>
      <UsersView />
    </Suspense>
  );
}
