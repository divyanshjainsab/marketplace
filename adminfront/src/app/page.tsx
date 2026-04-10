import Link from "next/link";

export default function HomePage() {
  return (
    <main className="min-h-screen px-6 py-12 text-slate-900">
      <div className="mx-auto max-w-5xl">
        <div className="rounded-[2rem] border border-slate-900/10 bg-white/70 p-10 shadow-[0_24px_80px_rgba(15,23,42,0.10)] backdrop-blur">
          <p className="inline-flex rounded-full bg-slate-900 px-4 py-1 text-xs font-semibold uppercase tracking-[0.3em] text-white">
            Adminfront
          </p>
          <h1 className="mt-6 text-balance text-4xl font-semibold tracking-tight md:text-6xl">
            Admin control plane
          </h1>
          <p className="mt-4 max-w-2xl text-base leading-7 text-slate-600 md:text-lg">
            Organization and marketplace management. Sign in through SSO and we will enforce admin-only access.
          </p>

          <div className="mt-8 flex flex-col gap-3 sm:flex-row">
            <Link
              href="/dashboard"
              className="inline-flex items-center justify-center rounded-2xl bg-slate-900 px-6 py-3 text-sm font-semibold text-white shadow-sm hover:bg-slate-800"
            >
              Open dashboard
            </Link>
            <Link
              href="/login"
              className="inline-flex items-center justify-center rounded-2xl border border-slate-200 bg-white px-6 py-3 text-sm font-semibold text-slate-900 shadow-sm hover:bg-slate-50"
            >
              Sign in
            </Link>
          </div>
        </div>
      </div>
    </main>
  );
}

