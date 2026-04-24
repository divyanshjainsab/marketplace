"use client";

import { useEffect, useMemo, useState } from "react";
import useSWR from "swr";
import { clientApiFetch } from "@/lib/client-api";
import { CloudinaryImage } from "@/components/media/cloudinary-image";
import { MediaUploadField } from "@/components/media/media-upload-field";
import type { Category, HomepageConfig, Listing, PaginatedResponse, Product, SiteEditorResponse } from "@/lib/types";
import { useWorkspace } from "@/components/providers/workspace-provider";
import { useToast } from "@/components/toast-provider";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";

const DEFAULT_ORDER: HomepageConfig["layout_order"] = [
  "hero_banner",
  "featured_products",
  "featured_listings",
  "categories",
  "promotional_blocks",
];

function normalizeConfig(raw: HomepageConfig | null | undefined): HomepageConfig {
  const config = raw ?? ({} as HomepageConfig);
  return {
    layout_order: (config.layout_order?.length ? config.layout_order : DEFAULT_ORDER) as HomepageConfig["layout_order"],
    hero_banner: config.hero_banner ?? { title: "Welcome", subtitle: "Explore the latest inventory." },
    featured_products: config.featured_products ?? [],
    featured_listings: config.featured_listings ?? [],
    categories: config.categories ?? [],
    promotional_blocks: config.promotional_blocks ?? [],
  };
}

export function SiteEditorScreen() {
  const { activeMarketplaceId, activeMarketplace, loading: workspaceLoading } = useWorkspace();
  const { notify } = useToast();

  const siteEditorKey = activeMarketplaceId ? `/v1/admin/site_editor?marketplace_id=${activeMarketplaceId}` : null;
  const siteEditorSwr = useSWR<SiteEditorResponse>(siteEditorKey, (path: string) => clientApiFetch<SiteEditorResponse>(path));

  const [draft, setDraft] = useState<HomepageConfig | null>(null);
  const [dirty, setDirty] = useState(false);
  const [saving, setSaving] = useState(false);

  const serverConfig = siteEditorSwr.data?.data?.homepage_config ?? null;

  useEffect(() => {
    if (!serverConfig) return;
    if (dirty) return;
    setDraft(normalizeConfig(serverConfig));
  }, [dirty, serverConfig]);

  const config = normalizeConfig(draft ?? serverConfig ?? undefined);

  const productsSwr = useSWR<PaginatedResponse<Product>>(
    activeMarketplaceId ? `/v1/admin/products?marketplace_id=${activeMarketplaceId}&page=1&per_page=100` : null,
    (path: string) => clientApiFetch<PaginatedResponse<Product>>(path),
  );

  const listingsSwr = useSWR<PaginatedResponse<Listing>>(
    activeMarketplaceId ? `/v1/admin/listings?marketplace_id=${activeMarketplaceId}&page=1&per_page=100` : null,
    (path: string) => clientApiFetch<PaginatedResponse<Listing>>(path),
  );

  const categoriesSwr = useSWR<PaginatedResponse<Category>>(
    activeMarketplaceId ? `/v1/admin/categories?marketplace_id=${activeMarketplaceId}&page=1&per_page=100` : null,
    (path: string) => clientApiFetch<PaginatedResponse<Category>>(path),
  );

  const productById = useMemo(() => new Map((productsSwr.data?.data ?? []).map((p) => [p.id, p])), [productsSwr.data?.data]);
  const listingById = useMemo(() => new Map((listingsSwr.data?.data ?? []).map((l) => [l.id, l])), [listingsSwr.data?.data]);
  const categoryByCode = useMemo(
    () => new Map((categoriesSwr.data?.data ?? []).map((c) => [c.code, c])),
    [categoriesSwr.data?.data],
  );

  function updateConfig(next: HomepageConfig) {
    setDraft(next);
    setDirty(true);
  }

  async function handleSave() {
    if (!activeMarketplaceId) return;
    setSaving(true);
    const previous = siteEditorSwr.data;
    try {
      const next = normalizeConfig(draft ?? config);
      if (previous) {
        siteEditorSwr.mutate({ ...previous, data: { ...previous.data, homepage_config: next } }, { revalidate: false });
      }
      const response = await clientApiFetch<SiteEditorResponse>(`/v1/admin/site_editor?marketplace_id=${activeMarketplaceId}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ homepage_config: next }),
      });
      setDraft(normalizeConfig(response.data.homepage_config));
      setDirty(false);
      siteEditorSwr.mutate(response, { revalidate: false });
      notify("Homepage updated", "success");
    } catch {
      if (previous) {
        siteEditorSwr.mutate(previous, { revalidate: false });
      }
      notify("Unable to save homepage config", "error");
    } finally {
      setSaving(false);
    }
  }

  function moveSection(section: HomepageConfig["layout_order"][number], direction: -1 | 1) {
    const order = [...config.layout_order];
    const idx = order.indexOf(section);
    const nextIdx = idx + direction;
    if (idx < 0) return;
    if (nextIdx < 0 || nextIdx >= order.length) return;
    order.splice(idx, 1);
    order.splice(nextIdx, 0, section);
    updateConfig({ ...config, layout_order: order });
  }

  const loading = workspaceLoading || siteEditorSwr.isLoading;

  return (
    <div className="space-y-5" data-tour="site-editor">
      <Card className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <p className="text-xs uppercase tracking-[0.25em] text-slate-500">CMS</p>
          <h1 className="mt-2 text-2xl font-semibold tracking-tight text-slate-950">Site Editor</h1>
          <p className="mt-2 text-sm text-slate-600">
            {activeMarketplace?.name
              ? `Configure the clientfront homepage for ${activeMarketplace.name}.`
              : "Configure the clientfront homepage for your organization."}
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button
            variant="secondary"
            onClick={() => {
              setDraft(normalizeConfig(serverConfig ?? undefined));
              setDirty(false);
            }}
            disabled={saving || !dirty}
          >
            Discard
          </Button>
          <Button variant="primary" onClick={handleSave} disabled={saving || loading}>
            {saving ? "Saving…" : "Save changes"}
          </Button>
        </div>
      </Card>

      {siteEditorSwr.error ? (
        <Card className="border-rose-200 bg-rose-50 text-rose-900">
          <p className="text-sm font-semibold">Unable to load homepage configuration.</p>
        </Card>
      ) : null}

      <div className="grid gap-6 lg:grid-cols-2">
        <div className="space-y-4">
          <Card className="bg-slate-50">
            <p className="text-xs font-semibold uppercase tracking-[0.25em] text-slate-500">Layout order</p>
            <div className="mt-4 space-y-2">
              {config.layout_order.map((section) => (
                <div key={section} className="flex items-center justify-between rounded-2xl border border-slate-200 bg-white px-4 py-3">
                  <p className="text-sm font-semibold text-slate-900">{section.replace(/_/g, " ")}</p>
                  <div className="flex items-center gap-2">
                    <Button variant="secondary" size="sm" onClick={() => moveSection(section, -1)} disabled={loading}>
                      Up
                    </Button>
                    <Button variant="secondary" size="sm" onClick={() => moveSection(section, 1)} disabled={loading}>
                      Down
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          </Card>

          <Card>
            <p className="text-xs font-semibold uppercase tracking-[0.25em] text-slate-500">Hero banner</p>
            {loading ? (
              <div className="mt-4 space-y-3">
                <Skeleton className="h-11 w-full" />
                <Skeleton className="h-11 w-full" />
              </div>
            ) : (
              <div className="mt-4 space-y-3">
                <Input
                  value={config.hero_banner?.title ?? ""}
                  onChange={(e) => updateConfig({ ...config, hero_banner: { ...(config.hero_banner ?? {}), title: e.target.value } })}
                  placeholder="Hero title"
                />
                <Input
                  value={config.hero_banner?.subtitle ?? ""}
                  onChange={(e) => updateConfig({ ...config, hero_banner: { ...(config.hero_banner ?? {}), subtitle: e.target.value } })}
                  placeholder="Hero subtitle"
                />
                <Input
                  value={config.hero_banner?.cta_text ?? ""}
                  onChange={(e) => updateConfig({ ...config, hero_banner: { ...(config.hero_banner ?? {}), cta_text: e.target.value } })}
                  placeholder="CTA text"
                />
                <Input
                  value={config.hero_banner?.cta_href ?? ""}
                  onChange={(e) => updateConfig({ ...config, hero_banner: { ...(config.hero_banner ?? {}), cta_href: e.target.value } })}
                  placeholder="CTA link (e.g. /products)"
                />
                <MediaUploadField
                  label="Hero image"
                  hint="Uploaded to Cloudinary and stored as versioned media metadata in the homepage config."
                  target="site_editor"
                  marketplaceId={activeMarketplaceId}
                  value={config.hero_banner?.image ?? null}
                  disabled={saving || loading}
                  onChange={(asset) =>
                    updateConfig({
                      ...config,
                      hero_banner: { ...(config.hero_banner ?? {}), image: asset ?? undefined },
                    })
                  }
                />
              </div>
            )}
          </Card>

          <Card>
            <p className="text-xs font-semibold uppercase tracking-[0.25em] text-slate-500">Featured products</p>
            <div className="mt-4 space-y-2">
              {(productsSwr.data?.data ?? []).slice(0, 50).map((product) => {
                const checked = (config.featured_products ?? []).includes(product.id);
                return (
                  <label key={product.id} className="flex cursor-pointer items-center justify-between rounded-2xl border border-slate-200 bg-white px-4 py-3">
                    <div>
                      <p className="text-sm font-semibold text-slate-900">{product.name}</p>
                      <p className="text-xs text-slate-500">{product.sku}</p>
                    </div>
                    <input
                      type="checkbox"
                      checked={checked}
                      onChange={(e) => {
                        const next = new Set(config.featured_products ?? []);
                        if (e.target.checked) next.add(product.id);
                        else next.delete(product.id);
                        updateConfig({ ...config, featured_products: Array.from(next).slice(0, 12) });
                      }}
                    />
                  </label>
                );
              })}
              {!productsSwr.isLoading && !(productsSwr.data?.data ?? []).length ? (
                <p className="text-sm text-slate-600">No products available for this store.</p>
              ) : null}
            </div>
          </Card>

          <Card>
            <p className="text-xs font-semibold uppercase tracking-[0.25em] text-slate-500">Featured listings</p>
            <div className="mt-4 space-y-2">
              {(listingsSwr.data?.data ?? []).slice(0, 50).map((listing) => {
                const checked = (config.featured_listings ?? []).includes(listing.id);
                return (
                  <label key={listing.id} className="flex cursor-pointer items-center justify-between rounded-2xl border border-slate-200 bg-white px-4 py-3">
                    <div>
                      <p className="text-sm font-semibold text-slate-900">{listing.product.name}</p>
                      <p className="text-xs text-slate-500">{listing.variant.name}</p>
                    </div>
                    <input
                      type="checkbox"
                      checked={checked}
                      onChange={(e) => {
                        const next = new Set(config.featured_listings ?? []);
                        if (e.target.checked) next.add(listing.id);
                        else next.delete(listing.id);
                        updateConfig({ ...config, featured_listings: Array.from(next).slice(0, 12) });
                      }}
                    />
                  </label>
                );
              })}
              {!listingsSwr.isLoading && !(listingsSwr.data?.data ?? []).length ? (
                <p className="text-sm text-slate-600">No listings available for this store.</p>
              ) : null}
            </div>
          </Card>

          <Card>
            <p className="text-xs font-semibold uppercase tracking-[0.25em] text-slate-500">Featured categories</p>
            <div className="mt-4 space-y-2">
              {(categoriesSwr.data?.data ?? []).slice(0, 60).map((category) => {
                const checked = (config.categories ?? []).includes(category.code);
                return (
                  <label key={category.code} className="flex cursor-pointer items-center justify-between rounded-2xl border border-slate-200 bg-white px-4 py-3">
                    <div>
                      <p className="text-sm font-semibold text-slate-900">{category.name}</p>
                      <p className="text-xs text-slate-500">{category.code}</p>
                    </div>
                    <input
                      type="checkbox"
                      checked={checked}
                      onChange={(e) => {
                        const next = new Set(config.categories ?? []);
                        if (e.target.checked) next.add(category.code);
                        else next.delete(category.code);
                        updateConfig({ ...config, categories: Array.from(next).slice(0, 12) });
                      }}
                    />
                  </label>
                );
              })}
              {!categoriesSwr.isLoading && !(categoriesSwr.data?.data ?? []).length ? (
                <p className="text-sm text-slate-600">No categories available.</p>
              ) : null}
            </div>
          </Card>

          <Card>
            <p className="text-xs font-semibold uppercase tracking-[0.25em] text-slate-500">Promotional blocks</p>
            <div className="mt-4 space-y-3">
              {(config.promotional_blocks ?? []).map((block, idx) => (
                <div key={idx} className="rounded-2xl border border-slate-200 bg-white p-4">
                  <div className="flex items-center justify-between">
                    <p className="text-sm font-semibold text-slate-900">Block {idx + 1}</p>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => {
                        const next = [...(config.promotional_blocks ?? [])];
                        next.splice(idx, 1);
                        updateConfig({ ...config, promotional_blocks: next });
                      }}
                    >
                      Remove
                    </Button>
                  </div>
                  <div className="mt-3 space-y-2">
                    <Input
                      value={block.title}
                      onChange={(e) => {
                        const next = [...(config.promotional_blocks ?? [])];
                        next[idx] = { ...block, title: e.target.value };
                        updateConfig({ ...config, promotional_blocks: next });
                      }}
                      placeholder="Title"
                    />
                    <Input
                      value={block.body ?? ""}
                      onChange={(e) => {
                        const next = [...(config.promotional_blocks ?? [])];
                        next[idx] = { ...block, body: e.target.value };
                        updateConfig({ ...config, promotional_blocks: next });
                      }}
                      placeholder="Body"
                    />
                    <Input
                      value={block.href ?? ""}
                      onChange={(e) => {
                        const next = [...(config.promotional_blocks ?? [])];
                        next[idx] = { ...block, href: e.target.value };
                        updateConfig({ ...config, promotional_blocks: next });
                      }}
                      placeholder="Link (e.g. /products)"
                    />
                    <MediaUploadField
                      label={`Promotional image ${idx + 1}`}
                      hint="CDN-served artwork for this promotional card."
                      target="site_editor"
                      marketplaceId={activeMarketplaceId}
                      value={block.image ?? null}
                      disabled={saving || loading}
                      onChange={(asset) => {
                        const next = [...(config.promotional_blocks ?? [])];
                        next[idx] = { ...block, image: asset ?? undefined };
                        updateConfig({ ...config, promotional_blocks: next });
                      }}
                    />
                  </div>
                </div>
              ))}
              <Button
                variant="secondary"
                onClick={() =>
                  updateConfig({
                    ...config,
                    promotional_blocks: [
                      ...(config.promotional_blocks ?? []),
                      { title: "Promotion", body: "Tell shoppers what’s new.", href: "/products" },
                    ].slice(0, 6),
                  })
                }
              >
                Add promotional block
              </Button>
            </div>
          </Card>
        </div>

        <div className="space-y-4">
          <Card className="bg-slate-50">
            <p className="text-xs font-semibold uppercase tracking-[0.25em] text-slate-500">Live preview</p>
            <div className="mt-4 space-y-6">
              {config.layout_order.map((section) => {
                if (section === "hero_banner") {
                  return (
                    <section key={section} className="rounded-3xl border border-slate-200 bg-white p-6">
                      <div className="grid gap-4 lg:grid-cols-[1.2fr_0.8fr] lg:items-center">
                        <div>
                          <p className="text-xs uppercase tracking-[0.25em] text-slate-500">Hero</p>
                          <h2 className="mt-3 text-2xl font-semibold text-slate-950">{config.hero_banner?.title ?? "Hero title"}</h2>
                          <p className="mt-2 text-sm text-slate-600">{config.hero_banner?.subtitle ?? ""}</p>
                          {config.hero_banner?.cta_text ? (
                            <div className="mt-4 inline-flex rounded-xl bg-slate-950 px-4 py-2 text-sm font-semibold text-white">
                              {config.hero_banner.cta_text}
                            </div>
                          ) : null}
                        </div>
                        <CloudinaryImage
                          asset={config.hero_banner?.image}
                          alt={config.hero_banner?.title ?? "Hero image"}
                          className="h-52 w-full"
                          fill
                          sizes="(min-width: 1024px) 22rem, 100vw"
                          fallbackLabel="Hero image"
                        />
                      </div>
                    </section>
                  );
                }

                if (section === "featured_products") {
                  return (
                    <section key={section} className="rounded-3xl border border-slate-200 bg-white p-6">
                      <p className="text-xs uppercase tracking-[0.25em] text-slate-500">Featured products</p>
                      <div className="mt-4 grid gap-3 md:grid-cols-2">
                        {(config.featured_products ?? []).map((id) => {
                          const product = productById.get(id);
                          if (!product) return null;
                          return (
                            <div key={id} className="flex items-center gap-3 rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3">
                              <CloudinaryImage asset={product.image} alt={product.name} className="h-14 w-14 shrink-0" sizes="56px" />
                              <div>
                                <p className="text-sm font-semibold text-slate-900">{product.name}</p>
                                <p className="text-xs text-slate-500">{product.sku}</p>
                              </div>
                            </div>
                          );
                        })}
                        {(config.featured_products ?? []).length === 0 ? (
                          <p className="text-sm text-slate-600">No featured products selected.</p>
                        ) : null}
                      </div>
                    </section>
                  );
                }

                if (section === "featured_listings") {
                  return (
                    <section key={section} className="rounded-3xl border border-slate-200 bg-white p-6">
                      <p className="text-xs uppercase tracking-[0.25em] text-slate-500">Featured listings</p>
                      <div className="mt-4 space-y-2">
                        {(config.featured_listings ?? []).map((id) => {
                          const listing = listingById.get(id);
                          if (!listing) return null;
                          return (
                            <div key={id} className="flex items-center gap-3 rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3">
                              <CloudinaryImage asset={listing.image} alt={listing.product.name} className="h-14 w-14 shrink-0" sizes="56px" />
                              <div>
                                <p className="text-sm font-semibold text-slate-900">{listing.product.name}</p>
                                <p className="text-xs text-slate-500">{listing.variant.name}</p>
                              </div>
                            </div>
                          );
                        })}
                        {(config.featured_listings ?? []).length === 0 ? (
                          <p className="text-sm text-slate-600">No featured listings selected.</p>
                        ) : null}
                      </div>
                    </section>
                  );
                }

                if (section === "categories") {
                  return (
                    <section key={section} className="rounded-3xl border border-slate-200 bg-white p-6">
                      <p className="text-xs uppercase tracking-[0.25em] text-slate-500">Categories</p>
                      <div className="mt-4 flex flex-wrap gap-2">
                        {(config.categories ?? []).map((code) => (
                          <span key={code} className="rounded-full border border-slate-200 bg-slate-50 px-3 py-1 text-xs font-semibold text-slate-700">
                            {categoryByCode.get(code)?.name ?? code}
                          </span>
                        ))}
                        {(config.categories ?? []).length === 0 ? (
                          <p className="text-sm text-slate-600">No categories selected.</p>
                        ) : null}
                      </div>
                    </section>
                  );
                }

                if (section === "promotional_blocks") {
                  return (
                    <section key={section} className="rounded-3xl border border-slate-200 bg-white p-6">
                      <p className="text-xs uppercase tracking-[0.25em] text-slate-500">Promotions</p>
                      <div className="mt-4 grid gap-3 md:grid-cols-2">
                        {(config.promotional_blocks ?? []).map((block, idx) => (
                          <div key={idx} className="overflow-hidden rounded-2xl border border-slate-200 bg-slate-50">
                            <CloudinaryImage
                              asset={block.image}
                              alt={block.title}
                              className="h-32 w-full"
                              fill
                              sizes="(min-width: 1024px) 14rem, 100vw"
                              fallbackLabel="Promo image"
                            />
                            <div className="px-4 py-3">
                              <p className="text-sm font-semibold text-slate-900">{block.title}</p>
                              {block.body ? <p className="mt-1 text-xs text-slate-600">{block.body}</p> : null}
                            </div>
                          </div>
                        ))}
                        {(config.promotional_blocks ?? []).length === 0 ? (
                          <p className="text-sm text-slate-600">No promotional blocks configured.</p>
                        ) : null}
                      </div>
                    </section>
                  );
                }

                return null;
              })}
            </div>
          </Card>
        </div>
      </div>
    </div>
  );
}
