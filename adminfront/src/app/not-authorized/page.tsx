import Link from "next/link";

export default function NotAuthorizedPage() {
  return (
    <main className="mx-auto flex min-h-[70vh] max-w-lg flex-col items-center justify-center px-6 py-16 text-center">
      <div className="w-full rounded-[2rem] border border-slate-900/10 bg-white/80 p-8 shadow-[0_24px_80px_rgba(15,23,42,0.10)] backdrop-blur">
        <p className="text-xs font-semibold uppercase tracking-[0.3em] text-slate-500">Access denied</p>
        <h1 className="mt-4 text-balance text-2xl font-semibold text-slate-900">Admin access is required</h1>
        <p className="mt-3 text-sm leading-6 text-slate-600">
          Your account does not have the roles needed to access the admin dashboard.
        </p>
        <div className="mt-6 flex flex-col gap-3 sm:flex-row sm:justify-center">
          <Link
            href="/login"
            className="inline-flex items-center justify-center rounded-2xl bg-slate-900 px-6 py-3 text-sm font-semibold text-white hover:bg-slate-800"
          >
            Sign in again
          </Link>
          <Link
            href="/"
            className="inline-flex items-center justify-center rounded-2xl border border-slate-200 bg-white px-6 py-3 text-sm font-semibold text-slate-900 hover:bg-slate-50"
          >
            Go home
          </Link>
        </div>
      </div>
    </main>
  );
}

