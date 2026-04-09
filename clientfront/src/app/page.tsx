export default function Home() {
  return (
    <main className="min-h-screen bg-[radial-gradient(circle_at_top,_rgba(235,94,40,0.18),_transparent_34%),linear-gradient(135deg,_#f7f4ea_0%,_#efe6d5_48%,_#e4dccf_100%)] px-6 py-10 text-stone-900">
      <div className="mx-auto flex min-h-[calc(100vh-5rem)] max-w-6xl flex-col justify-between rounded-[2rem] border border-stone-900/10 bg-white/70 p-8 shadow-[0_20px_80px_rgba(72,56,34,0.12)] backdrop-blur md:p-12">
        <div className="space-y-6">
          <span className="inline-flex rounded-full border border-stone-900/10 bg-stone-900 px-4 py-1 text-xs font-semibold uppercase tracking-[0.3em] text-stone-50">
            Clientfront
          </span>
          <div className="max-w-3xl space-y-4">
            <h1 className="text-4xl font-semibold tracking-tight text-balance md:text-6xl">
              Multi-tenant inventory system scaffold
            </h1>
            <p className="max-w-2xl text-base leading-7 text-stone-700 md:text-lg">
              Browse a tenant storefront publicly, then jump into the authenticated
              operations workspace for catalog and listing management.
            </p>
          </div>
        </div>

        <div className="grid gap-4 pt-10 md:grid-cols-3">
          <section className="rounded-3xl border border-stone-900/10 bg-stone-50 p-6">
            <p className="text-sm font-medium uppercase tracking-[0.2em] text-stone-500">
              Frontend
            </p>
            <p className="mt-3 text-sm leading-6 text-stone-700">
              Public marketplace browsing is available at <code>/products</code>.
            </p>
          </section>
          <section className="rounded-3xl border border-stone-900/10 bg-stone-50 p-6">
            <p className="text-sm font-medium uppercase tracking-[0.2em] text-stone-500">
              Backend API
            </p>
            <p className="mt-3 text-sm leading-6 text-stone-700">
              Connect to <code>{process.env.NEXT_PUBLIC_API_URL}</code> for API
              features once backend endpoints are added.
            </p>
          </section>
          <section className="rounded-3xl border border-stone-900/10 bg-stone-50 p-6">
            <p className="text-sm font-medium uppercase tracking-[0.2em] text-stone-500">
              SSO
            </p>
            <p className="mt-3 text-sm leading-6 text-stone-700">
              Use <code>/login</code> to hand off to SSO, receive JWT tokens,
              and enter the dashboard.
            </p>
          </section>
        </div>
      </div>
    </main>
  );
}
