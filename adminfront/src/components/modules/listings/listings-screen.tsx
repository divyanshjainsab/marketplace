"use client";

import { useEffect, useMemo, useState } from "react";
import useSWR from "swr";
import { ClientApiError, clientApiFetch } from "@/lib/client-api";
import { CloudinaryImage } from "@/components/media/cloudinary-image";
import { MediaUploadField } from "@/components/media/media-upload-field";
import type { Category, Listing, MediaAsset, PaginatedResponse, ProductSuggestion, ProductType } from "@/lib/types";
import { useWorkspace } from "@/components/providers/workspace-provider";
import { useToast } from "@/components/toast-provider";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Select } from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";

const DEFAULT_FORM = {
  productName: "",
  productSku: "",
  categoryId: "",
  productTypeId: "",
  variantName: "",
  variantSku: "",
  priceRupees: "",
  inventoryCount: "20",
  status: "draft",
  productImage: null as MediaAsset | null,
  variantImage: null as MediaAsset | null,
  listingImage: null as MediaAsset | null,
};

const STATUS_OPTIONS = ["draft", "active", "archived"] as const;

function formatMoney(priceCents: number | null, currency: string | null) {
  if (priceCents == null) return "Not set";
  const value = priceCents / 100;
  return new Intl.NumberFormat("en-IN", { style: "currency", currency: currency ?? "INR" }).format(value);
}

function priceInputFromCents(priceCents: number | null) {
  if (priceCents == null) return "";
  const amount = (priceCents / 100).toFixed(2);
  return amount.endsWith(".00") ? amount.slice(0, -3) : amount;
}

function centsFromPriceInput(value: string) {
  const normalized = value.trim();
  if (!normalized) return null;
  if (!/^\d+(?:\.\d{0,2})?$/.test(normalized)) return Number.NaN;

  return Math.round(Number(normalized) * 100);
}

export function ListingsScreen() {
  const { notify } = useToast();
  const { activeMarketplaceId, activeMarketplace, loading: workspaceLoading } = useWorkspace();
  const [page, setPage] = useState(1);
  const [categories, setCategories] = useState<Category[]>([]);
  const [productTypes, setProductTypes] = useState<ProductType[]>([]);
  const [form, setForm] = useState(DEFAULT_FORM);
  const [reuseProductId, setReuseProductId] = useState<number | null>(null);
  const [suggestions, setSuggestions] = useState<ProductSuggestion[]>([]);
  const [submitting, setSubmitting] = useState(false);
  const [drafts, setDrafts] = useState<Record<number, { priceRupees: string; inventoryCount: string; status: string }>>({});
  const [mutatingListingId, setMutatingListingId] = useState<number | null>(null);

  const key = useMemo(() => {
    if (!activeMarketplaceId) return null;
    const params = new URLSearchParams();
    params.set("marketplace_id", String(activeMarketplaceId));
    params.set("page", String(page));
    params.set("per_page", "12");
    return `/v1/admin/listings?${params.toString()}`;
  }, [activeMarketplaceId, page]);

  const listingsSwr = useSWR<PaginatedResponse<Listing>>(key, (path: string) => clientApiFetch<PaginatedResponse<Listing>>(path));
  const payload = listingsSwr.data ?? null;
  const loading = workspaceLoading || listingsSwr.isLoading;
  const suggestionQuery = useMemo(
    () => form.productName.trim() || form.productSku.trim(),
    [form.productName, form.productSku],
  );

  useEffect(() => {
    let active = true;

    Promise.all([
      clientApiFetch<PaginatedResponse<Category>>("/v1/categories?per_page=100"),
      clientApiFetch<PaginatedResponse<ProductType>>("/v1/product_types?per_page=100"),
    ])
      .then(([categoryPayload, productTypePayload]) => {
        if (!active) return;
        setCategories(categoryPayload.data);
        setProductTypes(productTypePayload.data);
      })
      .catch(() => {
        if (!active) return;
        notify("Unable to load listing metadata", "error");
      });

    return () => {
      active = false;
    };
  }, [notify]);

  useEffect(() => {
    if (!suggestionQuery) {
      setSuggestions([]);
      return;
    }

    const timer = window.setTimeout(() => {
      clientApiFetch<{ data: ProductSuggestion[] }>(`/v1/products/suggestions?q=${encodeURIComponent(suggestionQuery)}`)
        .then((response) => setSuggestions(response.data))
        .catch(() => setSuggestions([]));
    }, 300);

    return () => window.clearTimeout(timer);
  }, [suggestionQuery]);

  useEffect(() => {
    if (!payload?.data) return;

    setDrafts((current) => {
      const next: Record<number, { priceRupees: string; inventoryCount: string; status: string }> = {};

      for (const listing of payload.data) {
        next[listing.id] = current[listing.id] ?? {
          priceRupees: priceInputFromCents(listing.price_cents),
          inventoryCount: String(listing.inventory_count),
          status: listing.status ?? "active",
        };
      }

      return next;
    });
  }, [payload?.data]);

  function updateField(field: keyof typeof DEFAULT_FORM, value: string) {
    if ((field === "productName" || field === "productSku") && reuseProductId) {
      setReuseProductId(null);
    }

    setForm((current) => ({ ...current, [field]: value }));
  }

  function chooseSuggestion(suggestion: ProductSuggestion) {
    setReuseProductId(suggestion.product_id);
    setForm((current) => ({
      ...current,
      productName: suggestion.name,
      productSku: suggestion.sku,
    }));
    notify("Using existing shared product", "success");
  }

  function updateDraft(listingId: number, field: "priceRupees" | "inventoryCount" | "status", value: string) {
    setDrafts((current) => ({
      ...current,
      [listingId]: {
        priceRupees: current[listingId]?.priceRupees ?? "",
        inventoryCount: current[listingId]?.inventoryCount ?? "0",
        status: current[listingId]?.status ?? "active",
        [field]: value,
      },
    }));
  }

  async function createListing(forceCreate = false) {
    if (!activeMarketplaceId) {
      notify("Pick a store before creating a listing", "error");
      return;
    }

    if (!form.productName.trim() || !form.productSku.trim() || !form.variantName.trim() || !form.variantSku.trim()) {
      notify("Product and variant details are required", "error");
      return;
    }

    const priceCents = centsFromPriceInput(form.priceRupees);
    if (Number.isNaN(priceCents)) {
      notify("Enter a valid INR price with up to two decimals", "error");
      return;
    }

    const inventoryCount = Number(form.inventoryCount.trim());
    if (!Number.isInteger(inventoryCount) || inventoryCount < 0) {
      notify("Enter a valid inventory count (0 or more)", "error");
      return;
    }

    if (!reuseProductId && (!form.categoryId || !form.productTypeId)) {
      notify("Choose a category and product type", "error");
      return;
    }

    setSubmitting(true);

    try {
      await clientApiFetch(`/v1/admin/listings?marketplace_id=${activeMarketplaceId}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          listing: {
            reuse_product_id: reuseProductId ?? undefined,
            force_create: forceCreate,
            price_cents: priceCents,
            inventory_count: inventoryCount,
            currency: "INR",
            status: form.status,
            product: reuseProductId
              ? undefined
              : {
                  name: form.productName,
                  sku: form.productSku,
                  category_id: Number(form.categoryId),
                  product_type_id: Number(form.productTypeId),
                  image_data: form.productImage ?? undefined,
                },
            variant: {
              name: form.variantName,
              sku: form.variantSku,
              image_data: form.variantImage ?? undefined,
            },
            image_data: form.listingImage ?? undefined,
          },
        }),
      });

      setForm(DEFAULT_FORM);
      setReuseProductId(null);
      setSuggestions([]);
      setPage(1);
      await listingsSwr.mutate();
      notify("Listing created", "success");
    } catch (error) {
      if (error instanceof ClientApiError && error.status === 409) {
        const nextSuggestions =
          (error.details as { meta?: { suggestions?: ProductSuggestion[] } } | undefined)?.meta?.suggestions ?? [];
        setSuggestions(nextSuggestions);
        notify("Similar products found. Reuse one or create anyway.", "error");
      } else {
        notify(error instanceof Error ? error.message : "Unable to create listing", "error");
      }
    } finally {
      setSubmitting(false);
    }
  }

  async function saveListing(listing: Listing) {
    if (!activeMarketplaceId) {
      notify("Pick a store before updating a listing", "error");
      return;
    }

    const draft = drafts[listing.id] ?? {
      priceRupees: priceInputFromCents(listing.price_cents),
      inventoryCount: String(listing.inventory_count),
      status: listing.status ?? "active",
    };
    const priceCents = centsFromPriceInput(draft.priceRupees);
    if (Number.isNaN(priceCents)) {
      notify("Enter a valid INR price with up to two decimals", "error");
      return;
    }

    const inventoryCount = Number(draft.inventoryCount.trim());
    if (!Number.isInteger(inventoryCount) || inventoryCount < 0) {
      notify("Enter a valid inventory count (0 or more)", "error");
      return;
    }

    setMutatingListingId(listing.id);

    try {
      await clientApiFetch(`/v1/admin/listings/${listing.id}?marketplace_id=${activeMarketplaceId}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          listing: {
            price_cents: priceCents,
            inventory_count: inventoryCount,
            currency: "INR",
            status: draft.status,
          },
        }),
      });

      await listingsSwr.mutate();
      notify("Listing updated", "success");
    } catch (error) {
      notify(error instanceof Error ? error.message : "Unable to update listing", "error");
    } finally {
      setMutatingListingId(null);
    }
  }

  async function deleteListing(listing: Listing) {
    if (!activeMarketplaceId) {
      notify("Pick a store before deleting a listing", "error");
      return;
    }

    if (!window.confirm(`Delete ${listing.product.name} / ${listing.variant.name}?`)) {
      return;
    }

    setMutatingListingId(listing.id);

    try {
      await clientApiFetch(`/v1/admin/listings/${listing.id}?marketplace_id=${activeMarketplaceId}`, {
        method: "DELETE",
      });

      setDrafts((current) => {
        const next = { ...current };
        delete next[listing.id];
        return next;
      });
      await listingsSwr.mutate();
      notify("Listing deleted", "success");
    } catch (error) {
      notify(error instanceof Error ? error.message : "Unable to delete listing", "error");
    } finally {
      setMutatingListingId(null);
    }
  }

  return (
    <div className="space-y-5" data-tour="listings">
      <Card className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div>
          <p className="text-xs uppercase tracking-[0.25em] text-slate-500">Store inventory</p>
          <h1 className="mt-2 text-2xl font-semibold tracking-tight text-slate-950">Listings</h1>
          <p className="mt-2 text-sm text-slate-600">
            {activeMarketplace?.name ? `${activeMarketplace.name} listings and pricing.` : "Organization-scoped listings and pricing."}
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="secondary" onClick={() => listingsSwr.mutate()} disabled={loading}>
            Refresh
          </Button>
        </div>
      </Card>

      <div className="grid gap-5 xl:grid-cols-[0.95fr_1.05fr]">
        <Card className="bg-slate-50">
          <p className="text-xs uppercase tracking-[0.25em] text-slate-500">Suggestions</p>
          <h2 className="mt-2 text-xl font-semibold tracking-tight text-slate-950">Reuse global products</h2>
          <p className="mt-2 text-sm text-slate-600">Start with a shared product to avoid duplicate catalog records.</p>

          <div className="mt-5 space-y-3">
            {suggestions.length === 0 ? (
              <div className="rounded-2xl border border-dashed border-slate-300 bg-white px-4 py-6 text-sm text-slate-500">
                Search by product name or SKU to surface reusable catalog matches.
              </div>
            ) : (
              suggestions.map((suggestion) => (
                <button
                  key={suggestion.product_id}
                  type="button"
                  onClick={() => chooseSuggestion(suggestion)}
                  className={`block w-full rounded-2xl border px-4 py-4 text-left transition ${
                    reuseProductId === suggestion.product_id
                      ? "border-slate-950 bg-slate-950 text-white"
                      : "border-slate-200 bg-white text-slate-900 hover:border-slate-900"
                  }`}
                >
                  <p className="font-semibold">{suggestion.name}</p>
                  <p className="mt-1 text-sm opacity-80">{suggestion.sku}</p>
                </button>
              ))
            )}
          </div>
        </Card>

        <Card>
          <p className="text-xs uppercase tracking-[0.25em] text-slate-500">Create listing</p>
          <h2 className="mt-2 text-2xl font-semibold tracking-tight text-slate-950">Publish inventory to this store</h2>
          <p className="mt-2 text-sm text-slate-600">All listing prices are stored and enforced in INR.</p>

          <form
            className="mt-6 space-y-4"
            onSubmit={(event) => {
              event.preventDefault();
              createListing(false).catch(() => null);
            }}
          >
            <div className="grid gap-4 md:grid-cols-2">
              <Input
                required
                value={form.productName}
                onChange={(event) => updateField("productName", event.target.value)}
                placeholder="Product name"
              />
              <Input
                required
                value={form.productSku}
                onChange={(event) => updateField("productSku", event.target.value)}
                placeholder="Product SKU"
              />
            </div>

            {!reuseProductId ? (
              <div className="grid gap-4 md:grid-cols-2">
                <Select required value={form.categoryId} onChange={(event) => updateField("categoryId", event.target.value)}>
                  <option value="">Category</option>
                  {categories.map((category) => (
                    <option key={category.id} value={category.id}>
                      {category.name}
                    </option>
                  ))}
                </Select>
                <Select
                  required
                  value={form.productTypeId}
                  onChange={(event) => updateField("productTypeId", event.target.value)}
                >
                  <option value="">Product type</option>
                  {productTypes.map((productType) => (
                    <option key={productType.id} value={productType.id}>
                      {productType.name}
                    </option>
                  ))}
                </Select>
              </div>
            ) : (
              <div className="rounded-2xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-900">
                Reusing shared product ID {reuseProductId}. Edit the name or SKU to switch back to a new product.
              </div>
            )}

            <div className="grid gap-4 md:grid-cols-2">
              <Input
                required
                value={form.variantName}
                onChange={(event) => updateField("variantName", event.target.value)}
                placeholder="Variant name"
              />
              <Input
                required
                value={form.variantSku}
                onChange={(event) => updateField("variantSku", event.target.value)}
                placeholder="Variant SKU"
              />
            </div>

            <div className="grid gap-4 md:grid-cols-4">
              <Input
                required
                inputMode="decimal"
                value={form.priceRupees}
                onChange={(event) => updateField("priceRupees", event.target.value.replace(/[^\d.]/g, ""))}
                placeholder="Price in INR"
              />
              <Input
                required
                inputMode="numeric"
                value={form.inventoryCount}
                onChange={(event) => updateField("inventoryCount", event.target.value.replace(/[^\d]/g, ""))}
                placeholder="Inventory"
              />
              <div className="flex h-11 items-center rounded-xl border border-slate-200 bg-slate-50 px-3 text-sm text-slate-700">
                Currency: INR (₹)
              </div>
              <Select value={form.status} onChange={(event) => updateField("status", event.target.value)}>
                {STATUS_OPTIONS.map((status) => (
                  <option key={status} value={status}>
                    {status}
                  </option>
                ))}
              </Select>
            </div>

            <div className="grid gap-4 lg:grid-cols-3">
              {!reuseProductId ? (
                <MediaUploadField
                  label="Product image"
                  hint="Shared across every listing that reuses this product."
                  target="product"
                  marketplaceId={activeMarketplaceId}
                  value={form.productImage}
                  disabled={submitting}
                  onChange={(asset) => setForm((current) => ({ ...current, productImage: asset }))}
                />
              ) : null}
              <MediaUploadField
                label="Variant image"
                hint="Useful when variants need distinct color or style shots."
                target="variant"
                marketplaceId={activeMarketplaceId}
                value={form.variantImage}
                disabled={submitting}
                onChange={(asset) => setForm((current) => ({ ...current, variantImage: asset }))}
              />
              <MediaUploadField
                label="Listing image override"
                hint="Store-specific media takes precedence over variant and product images."
                target="listing"
                marketplaceId={activeMarketplaceId}
                value={form.listingImage}
                disabled={submitting}
                onChange={(asset) => setForm((current) => ({ ...current, listingImage: asset }))}
              />
            </div>

            <div className="flex flex-col gap-3 md:flex-row">
              <Button type="submit" variant="primary" disabled={submitting || !activeMarketplaceId}>
                {submitting ? "Saving..." : "Create listing"}
              </Button>
              <Button
                type="button"
                variant="secondary"
                disabled={submitting || !activeMarketplaceId}
                onClick={() => createListing(true).catch(() => null)}
              >
                Create new product anyway
              </Button>
            </div>
          </form>
        </Card>
      </div>

      {listingsSwr.error ? (
        <Card className="border-rose-200 bg-rose-50 text-rose-900">
          <p className="text-sm font-semibold">Unable to load listings.</p>
        </Card>
      ) : null}

      <div className="overflow-hidden rounded-[1.75rem] border border-slate-200 bg-white">
        <table className="min-w-full divide-y divide-slate-200 text-left text-sm">
          <thead className="bg-slate-50 text-slate-500">
            <tr>
              <th className="px-4 py-3 font-medium">Product</th>
              <th className="px-4 py-3 font-medium">Variant</th>
              <th className="px-4 py-3 font-medium">Status</th>
              <th className="px-4 py-3 font-medium">Price</th>
              <th className="px-4 py-3 font-medium">Inventory</th>
              <th className="px-4 py-3 font-medium">Updated</th>
              <th className="px-4 py-3 font-medium">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 bg-white">
            {loading ? (
              Array.from({ length: 6 }).map((_, idx) => (
                <tr key={idx}>
                  <td className="px-4 py-3">
                    <Skeleton className="h-4 w-48" />
                    <Skeleton className="mt-2 h-3 w-28" />
                  </td>
                  <td className="px-4 py-3">
                    <Skeleton className="h-4 w-32" />
                  </td>
                  <td className="px-4 py-3">
                    <Skeleton className="h-4 w-20" />
                  </td>
                  <td className="px-4 py-3">
                    <Skeleton className="h-4 w-24" />
                  </td>
                  <td className="px-4 py-3">
                    <Skeleton className="h-4 w-20" />
                  </td>
                  <td className="px-4 py-3">
                    <Skeleton className="h-4 w-36" />
                  </td>
                  <td className="px-4 py-3">
                    <Skeleton className="h-9 w-28" />
                  </td>
                </tr>
              ))
            ) : (payload?.data ?? []).length ? (
              (payload?.data ?? []).map((listing) => (
                <tr key={listing.id}>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-3">
                      <CloudinaryImage
                        asset={listing.image}
                        alt={listing.product.name}
                        className="h-16 w-16 shrink-0"
                        sizes="64px"
                        fallbackLabel="No image"
                      />
                      <div>
                        <p className="font-medium text-slate-900">{listing.product.name}</p>
                        <p className="text-xs text-slate-500">{listing.product.sku}</p>
                        {listing.image_source ? (
                          <p className="mt-1 text-[11px] font-semibold uppercase tracking-[0.18em] text-slate-400">
                            {listing.image_source} image
                          </p>
                        ) : null}
                      </div>
                    </div>
                  </td>
                  <td className="px-4 py-3 text-slate-600">{listing.variant.name}</td>
                  <td className="px-4 py-3">
                    <Select
                      value={drafts[listing.id]?.status ?? listing.status ?? "active"}
                      onChange={(event) => updateDraft(listing.id, "status", event.target.value)}
                      disabled={mutatingListingId === listing.id}
                      className="h-10 min-w-[130px]"
                    >
                      {STATUS_OPTIONS.map((status) => (
                        <option key={status} value={status}>
                          {status}
                        </option>
                      ))}
                    </Select>
                  </td>
                  <td className="px-4 py-3">
                    <Input
                      inputMode="decimal"
                      value={drafts[listing.id]?.priceRupees ?? priceInputFromCents(listing.price_cents)}
                      onChange={(event) => updateDraft(listing.id, "priceRupees", event.target.value.replace(/[^\d.]/g, ""))}
                      disabled={mutatingListingId === listing.id}
                      className="h-10 min-w-[140px]"
                    />
                    <p className="mt-1 text-xs text-slate-500">
                      {formatMoney(listing.price_cents, listing.currency)}
                    </p>
                  </td>
                  <td className="px-4 py-3">
                    <Input
                      inputMode="numeric"
                      value={drafts[listing.id]?.inventoryCount ?? String(listing.inventory_count)}
                      onChange={(event) => updateDraft(listing.id, "inventoryCount", event.target.value.replace(/[^\d]/g, ""))}
                      disabled={mutatingListingId === listing.id}
                      className="h-10 min-w-[110px]"
                    />
                    <p className="mt-1 text-xs text-slate-500">
                      {listing.inventory_count <= 0 ? "Out of stock" : `${listing.inventory_count} available`}
                    </p>
                  </td>
                  <td className="px-4 py-3 text-slate-500">{new Date(listing.updated_at).toLocaleString()}</td>
                  <td className="px-4 py-3">
                    <div className="flex flex-wrap gap-2">
                      <Button
                        variant="secondary"
                        size="sm"
                        onClick={() => saveListing(listing).catch(() => null)}
                        disabled={mutatingListingId === listing.id}
                      >
                        {mutatingListingId === listing.id ? "Saving..." : "Save"}
                      </Button>
                      <Button
                        variant="danger"
                        size="sm"
                        onClick={() => deleteListing(listing).catch(() => null)}
                        disabled={mutatingListingId === listing.id}
                      >
                        Delete
                      </Button>
                    </div>
                  </td>
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan={7} className="px-4 py-10 text-center text-sm text-slate-600">
                  No listings found for this store.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      <div className="flex items-center justify-between">
        <Button variant="secondary" onClick={() => setPage((current) => Math.max(current - 1, 1))} disabled={page <= 1 || loading}>
          Previous
        </Button>
        <p className="text-sm text-slate-500">
          Page {payload?.meta.page ?? page} of {payload?.meta.total_pages ?? 1}
        </p>
        <Button
          variant="secondary"
          onClick={() => setPage((current) => current + 1)}
          disabled={loading || page >= (payload?.meta.total_pages ?? 1)}
        >
          Next
        </Button>
      </div>
    </div>
  );
}
