export default function DashboardPage() {
  return (
    <div className="space-y-6">
      <header className="rounded-[1.75rem] border border-slate-900/10 bg-white p-6">
        <p className="text-xs font-semibold uppercase tracking-[0.3em] text-slate-500">Admin</p>
        <h1 className="mt-3 text-2xl font-semibold tracking-tight text-slate-950">Dashboard</h1>
        <p className="mt-2 text-sm text-slate-600">Manage organizations, marketplaces, users, and catalog.</p>
      </header>
      <section className="grid gap-4 md:grid-cols-3">
        {[
          { label: "Users", value: "Directory" },
          { label: "Marketplaces", value: "Inventory" },
          { label: "Listings", value: "Operations" },
        ].map((card) => (
          <article key={card.label} className="rounded-[1.75rem] border border-slate-900/10 bg-slate-50 p-6">
            <p className="text-xs font-semibold uppercase tracking-[0.25em] text-slate-500">{card.label}</p>
            <p className="mt-4 text-3xl font-semibold text-slate-950">{card.value}</p>
          </article>
        ))}
      </section>
    </div>
  );
}

