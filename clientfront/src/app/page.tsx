import Link from "next/link";
import { apiFetch } from "@/lib/api";
import type { HomepageResponse } from "@/lib/types";

function heroTitle(payload: HomepageResponse | null) {
  return payload?.data.homepage_config?.hero_banner?.title ?? payload?.data.marketplace?.name ?? "Marketplace";
}

export default async function Home() {
  let payload: HomepageResponse | null = null;
  try {
    payload = await apiFetch<HomepageResponse>("/api/v1/homepage");
  } catch {
    payload = null;
  }

  const config = payload?.data.homepage_config;
  const resolved = payload?.data.resolved;
  const order = config?.layout_order?.length ? config.layout_order : ["hero_banner", "featured_products", "categories", "promotional_blocks"];

  return (
    <main className="min-h-screen bg-[radial-gradient(circle_at_top,_rgba(235,94,40,0.18),_transparent_34%),linear-gradient(135deg,_#f7f4ea_0%,_#efe6d5_48%,_#e4dccf_100%)] px-6 py-10 text-stone-900">
      <div className="mx-auto max-w-6xl space-y-8 rounded-[2rem] border border-stone-900/10 bg-white/70 p-8 shadow-[0_20px_80px_rgba(72,56,34,0.12)] backdrop-blur md:p-12">
        {order.map((section) => {
          if (section === "hero_banner") {
            return (
              <header key={section} className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
                <div className="space-y-3">
                  <span className="inline-flex rounded-full border border-stone-900/10 bg-stone-900 px-4 py-1 text-xs font-semibold uppercase tracking-[0.3em] text-stone-50">
                    {payload?.data.marketplace?.name ?? "Storefront"}
                  </span>
                  <h1 className="text-balance text-4xl font-semibold tracking-tight md:text-6xl">{heroTitle(payload)}</h1>
                  <p className="max-w-2xl text-base leading-7 text-stone-700 md:text-lg">
                    {config?.hero_banner?.subtitle ?? "Discover what’s new in this marketplace."}
                  </p>
                </div>
                <div className="flex items-center gap-3">
                  <Link
                    href={config?.hero_banner?.cta_href ?? "/products"}
                    className="inline-flex items-center justify-center rounded-2xl bg-stone-900 px-6 py-3 text-sm font-semibold text-stone-50 shadow-sm hover:bg-stone-800"
                  >
                    {config?.hero_banner?.cta_text ?? "Browse products"}
                  </Link>
                </div>
              </header>
            );
          }

          if (section === "featured_products") {
            return (
              <section key={section} className="rounded-3xl border border-stone-900/10 bg-stone-50 p-6">
                <div className="flex items-center justify-between">
                  <h2 className="text-lg font-semibold">Featured products</h2>
                  <Link href="/products" className="text-sm font-semibold text-stone-700 hover:text-stone-900">
                    View all
                  </Link>
                </div>
                <div className="mt-4 grid gap-4 md:grid-cols-3">
                  {(resolved?.featured_products ?? []).map((product) => (
                    <article key={product.id} className="rounded-3xl border border-stone-900/10 bg-white p-5">
                      <p className="text-sm font-semibold text-stone-900">{product.name}</p>
                      <p className="mt-1 text-xs text-stone-500">{product.category?.name}</p>
                      <p className="mt-4 text-xs font-semibold uppercase tracking-[0.2em] text-stone-400">
                        SKU {product.sku}
                      </p>
                    </article>
                  ))}
                  {(resolved?.featured_products ?? []).length === 0 ? (
                    <p className="text-sm text-stone-600">No featured products configured yet.</p>
                  ) : null}
                </div>
              </section>
            );
          }

          if (section === "featured_listings") {
            return (
              <section key={section} className="rounded-3xl border border-stone-900/10 bg-stone-50 p-6">
                <h2 className="text-lg font-semibold">Featured listings</h2>
                <div className="mt-4 grid gap-4 md:grid-cols-3">
                  {(resolved?.featured_listings ?? []).map((listing) => (
                    <article key={listing.id} className="rounded-3xl border border-stone-900/10 bg-white p-5">
                      <p className="text-sm font-semibold text-stone-900">{listing.product.name}</p>
                      <p className="mt-1 text-xs text-stone-500">{listing.variant.name}</p>
                      <p className="mt-4 text-xs text-stone-500">{listing.status ?? "active"}</p>
                    </article>
                  ))}
                  {(resolved?.featured_listings ?? []).length === 0 ? (
                    <p className="text-sm text-stone-600">No featured listings configured yet.</p>
                  ) : null}
                </div>
              </section>
            );
          }

          if (section === "categories") {
            return (
              <section key={section} className="rounded-3xl border border-stone-900/10 bg-stone-50 p-6">
                <h2 className="text-lg font-semibold">Shop by category</h2>
                <div className="mt-4 flex flex-wrap gap-2">
                  {(resolved?.categories ?? []).map((category) => (
                    <Link
                      key={category.code}
                      href={`/products?q=${encodeURIComponent(category.name)}`}
                      className="rounded-full border border-stone-900/10 bg-white px-4 py-2 text-sm font-semibold text-stone-800 hover:bg-stone-100"
                    >
                      {category.name}
                    </Link>
                  ))}
                  {(resolved?.categories ?? []).length === 0 ? (
                    <p className="text-sm text-stone-600">No featured categories configured yet.</p>
                  ) : null}
                </div>
              </section>
            );
          }

          if (section === "promotional_blocks") {
            return (
              <section key={section} className="rounded-3xl border border-stone-900/10 bg-stone-50 p-6">
                <h2 className="text-lg font-semibold">Promotions</h2>
                <div className="mt-4 grid gap-4 md:grid-cols-2">
                  {(config?.promotional_blocks ?? []).map((block, idx) => (
                    <article key={idx} className="rounded-3xl border border-stone-900/10 bg-white p-6">
                      <p className="text-sm font-semibold text-stone-900">{block.title}</p>
                      {block.body ? <p className="mt-2 text-sm text-stone-600">{block.body}</p> : null}
                      {block.href ? (
                        <Link href={block.href} className="mt-4 inline-flex text-sm font-semibold text-stone-800 hover:text-stone-900">
                          Explore →
                        </Link>
                      ) : null}
                    </article>
                  ))}
                  {(config?.promotional_blocks ?? []).length === 0 ? (
                    <p className="text-sm text-stone-600">No promotional blocks configured yet.</p>
                  ) : null}
                </div>
              </section>
            );
          }

          return null;
        })}

        <footer className="rounded-3xl border border-stone-900/10 bg-stone-50 p-6 text-sm text-stone-700">
          <p>
            Powered by{" "}
            <span className="font-semibold">{payload?.data.organization?.name ?? "your organization"}</span>. Manage this homepage from the admin dashboard.
          </p>
        </footer>
      </div>
    </main>
  );
}
