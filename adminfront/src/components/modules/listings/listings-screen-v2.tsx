"use client";

import { useDeferredValue, useEffect, useMemo, useState } from "react";
import useSWR from "swr";
import { ClientApiError, clientApiFetch } from "@/lib/client-api";
import { CloudinaryImage } from "@/components/media/cloudinary-image";
import { MediaUploadGrid } from "@/components/media/media-upload-grid";
import type {
  AdminSettingsResponse,
  AdminSharingScope,
  Category,
  Listing,
  MediaAsset,
  PaginatedResponse,
  ProductSuggestion,
  ProductType,
} from "@/lib/types";
import { useWorkspace } from "@/components/providers/workspace-provider";
import { useToast } from "@/components/toast-provider";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { FormField } from "@/components/ui/form-field";
import { Input } from "@/components/ui/input";
import { ConfirmDialog } from "@/components/ui/modal";
import { PageHeader } from "@/components/ui/page-header";
import { Select } from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import { Table, Td, Th, Tr } from "@/components/ui/table";
import { Heading, Text } from "@/components/ui/typography";

type ListingFormState = {
  productName: string;
  productSku: string;
  categoryId: string;
  productTypeId: string;
  size: string;
  color: string;
  variantSku: string;
  priceRupees: string;
  inventoryCount: string;
  status: string;
  productImage: MediaAsset | null;
  variantImage: MediaAsset | null;
  listingImage: MediaAsset | null;
};

type ListingDraft = {
  priceRupees: string;
  inventoryCount: string;
  status: string;
};

type ListingFormErrors = Partial<Record<keyof ListingFormState | "form", string>>;

const DEFAULT_FORM: ListingFormState = {
  productName: "",
  productSku: "",
  categoryId: "",
  productTypeId: "",
  size: "",
  color: "",
  variantSku: "",
  priceRupees: "",
  inventoryCount: "20",
  status: "draft",
  productImage: null,
  variantImage: null,
  listingImage: null,
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

function variantDisplayName(size: string, color: string) {
  const parts = [size.trim(), color.trim()].filter(Boolean);
  return parts.length ? parts.join(" / ") : "Default variant";
}

function sharingCopy(scope: AdminSharingScope | null) {
  switch (scope) {
    case "disabled":
      return "Product sharing is off for this organization. Listings will create new products unless you switch the setting on.";
    case "organization":
      return "Isolation mode is on. Suggestions are limited to products already used inside this organization.";
    case "global":
      return "Global reuse is enabled. Suggestions can pull from the wider shared catalog.";
    default:
      return "Loading product sharing rules for this organization.";
  }
}

function validationErrorFor(error: unknown) {
  if (!(error instanceof ClientApiError)) {
    return {};
  }

  const details = (error.details as { error?: { details?: Record<string, string[] | string> } } | undefined)?.error?.details;
  if (!details) return {};

  const next: ListingFormErrors = {};
  const entries = Object.entries(details);

  for (const [key, value] of entries) {
    const message = Array.isArray(value) ? value[0] : value;
    if (!message) continue;

    if (key.includes("category")) next.categoryId = message;
    if (key.includes("product_type")) next.productTypeId = message;
    if (key === "price_cents") next.priceRupees = message;
    if (key === "inventory_count") next.inventoryCount = message;
    if (key === "sku" && !next.variantSku) next.variantSku = message;
    if (key === "name" && !next.productName) next.productName = message;
  }

  return next;
}

export function ListingsScreenV2() {
  const { notify } = useToast();
  const { activeMarketplaceId, activeMarketplace, loading: workspaceLoading } = useWorkspace();
  const [page, setPage] = useState(1);
  const [categories, setCategories] = useState<Category[]>([]);
  const [productTypes, setProductTypes] = useState<ProductType[]>([]);
  const [sharingScope, setSharingScope] = useState<AdminSharingScope | null>(null);
  const [loadingMetadata, setLoadingMetadata] = useState(false);
  const [form, setForm] = useState<ListingFormState>(DEFAULT_FORM);
  const [errors, setErrors] = useState<ListingFormErrors>({});
  const [reuseProductId, setReuseProductId] = useState<number | null>(null);
  const [suggestions, setSuggestions] = useState<ProductSuggestion[]>([]);
  const [submitting, setSubmitting] = useState(false);
  const [drafts, setDrafts] = useState<Record<number, ListingDraft>>({});
  const [mutatingListingId, setMutatingListingId] = useState<number | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<Listing | null>(null);

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
  const suggestionQuery = useDeferredValue(form.productName.trim() || form.productSku.trim());

  useEffect(() => {
    if (!activeMarketplaceId) return;

    let active = true;
    setLoadingMetadata(true);

    Promise.all([
      clientApiFetch<PaginatedResponse<Category>>(`/v1/admin/categories?marketplace_id=${activeMarketplaceId}&per_page=200`),
      clientApiFetch<PaginatedResponse<ProductType>>(`/v1/admin/product_types?marketplace_id=${activeMarketplaceId}&per_page=200`),
      clientApiFetch<AdminSettingsResponse>(`/v1/admin/settings?marketplace_id=${activeMarketplaceId}`),
    ])
      .then(([categoryPayload, productTypePayload, settingsPayload]) => {
        if (!active) return;
        setCategories(categoryPayload.data);
        setProductTypes(productTypePayload.data);
        setSharingScope(settingsPayload.data.sharing_scope);
      })
      .catch(() => {
        if (!active) return;
        notify("Unable to load listing metadata", "error");
      })
      .finally(() => {
        if (active) setLoadingMetadata(false);
      });

    return () => {
      active = false;
    };
  }, [activeMarketplaceId, notify]);

  useEffect(() => {
    if (!suggestionQuery || sharingScope === "disabled") {
      setSuggestions([]);
      return;
    }

    let active = true;
    const timer = window.setTimeout(() => {
      clientApiFetch<{ data: ProductSuggestion[] }>(`/v1/products/suggestions?q=${encodeURIComponent(suggestionQuery)}`)
        .then((response) => {
          if (active) setSuggestions(response.data);
        })
        .catch(() => {
          if (active) setSuggestions([]);
        });
    }, 300);

    return () => {
      active = false;
      window.clearTimeout(timer);
    };
  }, [sharingScope, suggestionQuery]);

  useEffect(() => {
    if (!payload?.data) return;

    setDrafts((current) => {
      const next: Record<number, ListingDraft> = {};

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

  function updateField(field: keyof ListingFormState, value: string | MediaAsset | null) {
    if ((field === "productName" || field === "productSku") && reuseProductId) {
      setReuseProductId(null);
    }

    setErrors((current) => ({ ...current, [field]: undefined, form: undefined }));
    setForm((current) => ({ ...current, [field]: value as never }));
  }

  function chooseSuggestion(suggestion: ProductSuggestion) {
    setReuseProductId(suggestion.product_id);
    setErrors({});
    setForm((current) => ({
      ...current,
      productName: suggestion.name,
      productSku: suggestion.sku,
    }));
    notify("Using an existing product suggestion", "success");
  }

  function updateDraft(listingId: number, field: keyof ListingDraft, value: string) {
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

  function validateForm() {
    const nextErrors: ListingFormErrors = {};

    if (!form.productName.trim()) nextErrors.productName = "Enter a product name.";
    if (!form.productSku.trim()) nextErrors.productSku = "Enter a product SKU.";
    if (!reuseProductId && !form.categoryId) nextErrors.categoryId = "Choose a category.";
    if (!reuseProductId && !form.productTypeId) nextErrors.productTypeId = "Choose a product type.";
    if (!form.size.trim()) nextErrors.size = "Enter a size for this variant.";
    if (!form.color.trim()) nextErrors.color = "Enter a color for this variant.";
    if (!form.variantSku.trim()) nextErrors.variantSku = "Enter a variant SKU.";

    const priceCents = centsFromPriceInput(form.priceRupees);
    if (priceCents == null) {
      nextErrors.priceRupees = "Enter a price in INR.";
    } else if (Number.isNaN(priceCents)) {
      nextErrors.priceRupees = "Use up to two decimals for the price.";
    }

    const inventoryCount = Number(form.inventoryCount.trim());
    if (!form.inventoryCount.trim()) {
      nextErrors.inventoryCount = "Enter inventory for this listing.";
    } else if (!Number.isInteger(inventoryCount) || inventoryCount < 0) {
      nextErrors.inventoryCount = "Inventory must be a whole number that is 0 or more.";
    }

    return nextErrors;
  }

  async function createListing(forceCreate = false) {
    if (!activeMarketplaceId) {
      notify("Pick a store before creating a listing", "error");
      return;
    }

    const nextErrors = validateForm();
    setErrors(nextErrors);

    if (Object.values(nextErrors).some(Boolean)) {
      notify("Fix the highlighted listing fields and try again", "error");
      return;
    }

    const priceCents = centsFromPriceInput(form.priceRupees);
    const inventoryCount = Number(form.inventoryCount.trim());

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
                  name: form.productName.trim(),
                  sku: form.productSku.trim(),
                  category_id: Number(form.categoryId),
                  product_type_id: Number(form.productTypeId),
                  image_data: form.productImage ?? undefined,
                },
            variant: {
              name: variantDisplayName(form.size, form.color),
              sku: form.variantSku.trim(),
              image_data: form.variantImage ?? undefined,
            },
            variant_options: {
              size: form.size.trim(),
              color: form.color.trim(),
            },
            image_data: form.listingImage ?? undefined,
          },
        }),
      });

      setForm(DEFAULT_FORM);
      setErrors({});
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
        setErrors((current) => ({
          ...current,
          form: "Similar products were found. Pick one to reuse, or create a new product anyway.",
        }));
        notify("Similar products found. Reuse one or create anyway.", "error");
      } else {
        const serverErrors = validationErrorFor(error);
        setErrors((current) => ({
          ...current,
          ...serverErrors,
          form: error instanceof Error ? error.message : "Unable to create listing",
        }));
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
    if (priceCents == null) {
      notify("Price is required for every listing", "error");
      return;
    }

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

  async function confirmDeleteTarget() {
    if (!deleteTarget) return;
    await deleteListing(deleteTarget);
    setDeleteTarget(null);
  }

  return (
    <div className="space-y-6" data-tour="listings">
      <PageHeader
        kicker="Store inventory"
        title="Listings"
        description={
          activeMarketplace?.name
            ? `${activeMarketplace.name} listings, pricing, images, and catalog reuse.`
            : "Organization-scoped listings and pricing."
        }
        actions={
          <Button variant="secondary" onClick={() => listingsSwr.mutate()} disabled={loading}>
            Refresh listings
          </Button>
        }
      />

      <div className="grid gap-6 xl:grid-cols-[minmax(0,1.25fr)_minmax(0,0.85fr)]">
        <Card>
          <Text variant="kicker">Create listing</Text>
          <Heading as="h2" size="h2" className="mt-2">
            Publish inventory to this store
          </Heading>
          <Text variant="muted" className="mt-2">
            Every required field is labeled below, inline errors are shown immediately, and prices are enforced in INR.
          </Text>

          {!loadingMetadata && (!categories.length || !productTypes.length) ? (
            <div className="mt-6 rounded-2xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-900">
              Categories and product types must exist before you can create a new product-backed listing. Add them from the Catalog page if this store is missing setup data.
            </div>
          ) : null}

          {errors.form ? (
            <div className="mt-6 rounded-2xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-900">{errors.form}</div>
          ) : null}

          <form
            className="mt-6 space-y-6"
            onSubmit={(event) => {
              event.preventDefault();
              createListing(false).catch(() => null);
            }}
          >
            <section className="grid gap-4 md:grid-cols-2">
              <FormField
                label="Product name"
                hint="Customer-facing name for the product that this listing belongs to."
                error={errors.productName}
                required
              >
                {({ id, describedBy, invalid }) => (
                  <Input
                    id={id}
                    required
                    value={form.productName}
                    onChange={(event) => updateField("productName", event.target.value)}
                    placeholder="Classic cotton tee"
                    aria-invalid={invalid}
                    aria-describedby={describedBy}
                  />
                )}
              </FormField>

              <FormField
                label="Product SKU"
                hint="Use a stable unique SKU so this product can be reused safely later."
                error={errors.productSku}
                required
              >
                {({ id, describedBy, invalid }) => (
                  <Input
                    id={id}
                    required
                    value={form.productSku}
                    onChange={(event) => updateField("productSku", event.target.value.toUpperCase())}
                    placeholder="TEE-COTTON-001"
                    aria-invalid={invalid}
                    aria-describedby={describedBy}
                    autoCapitalize="characters"
                  />
                )}
              </FormField>
            </section>

            {!reuseProductId ? (
              <section className="grid gap-4 md:grid-cols-2">
                <FormField
                  label="Category"
                  hint="Categories power browsing and merchandising for this product."
                  error={errors.categoryId}
                  required
                >
                  {({ id, describedBy, invalid }) => (
                    <Select
                      id={id}
                      required
                      value={form.categoryId}
                      onChange={(event) => updateField("categoryId", event.target.value)}
                      aria-invalid={invalid}
                      aria-describedby={describedBy}
                      disabled={loadingMetadata}
                    >
                      <option value="">Select a category</option>
                      {categories.map((category) => (
                        <option key={category.id} value={category.id}>
                          {category.name}
                        </option>
                      ))}
                    </Select>
                  )}
                </FormField>

                <FormField
                  label="Product type"
                  hint="Choose the top-level product type used for reporting and taxonomy."
                  error={errors.productTypeId}
                  required
                >
                  {({ id, describedBy, invalid }) => (
                    <Select
                      id={id}
                      required
                      value={form.productTypeId}
                      onChange={(event) => updateField("productTypeId", event.target.value)}
                      aria-invalid={invalid}
                      aria-describedby={describedBy}
                      disabled={loadingMetadata}
                    >
                      <option value="">Select a product type</option>
                      {productTypes.map((productType) => (
                        <option key={productType.id} value={productType.id}>
                          {productType.name}
                        </option>
                      ))}
                    </Select>
                  )}
                </FormField>
              </section>
            ) : (
              <div className="rounded-2xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-900">
                Reusing product ID {reuseProductId}. Change the product name or SKU if you want to switch back to creating a new product.
              </div>
            )}

            <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
              <FormField
                label="Variant size"
                hint="Required for the sellable variant attached to this listing."
                error={errors.size}
                required
              >
                {({ id, describedBy, invalid }) => (
                  <Input
                    id={id}
                    required
                    value={form.size}
                    onChange={(event) => updateField("size", event.target.value)}
                    placeholder="M"
                    aria-invalid={invalid}
                    aria-describedby={describedBy}
                  />
                )}
              </FormField>

              <FormField
                label="Variant color"
                hint="Use the customer-facing color name shown in inventory and orders."
                error={errors.color}
                required
              >
                {({ id, describedBy, invalid }) => (
                  <Input
                    id={id}
                    required
                    value={form.color}
                    onChange={(event) => updateField("color", event.target.value)}
                    placeholder="Black"
                    aria-invalid={invalid}
                    aria-describedby={describedBy}
                  />
                )}
              </FormField>

              <FormField
                label="Variant SKU"
                hint={`Variant label will be saved as ${variantDisplayName(form.size, form.color)}.`}
                error={errors.variantSku}
                required
              >
                {({ id, describedBy, invalid }) => (
                  <Input
                    id={id}
                    required
                    value={form.variantSku}
                    onChange={(event) => updateField("variantSku", event.target.value.toUpperCase())}
                    placeholder="TEE-COTTON-001-M-BLACK"
                    aria-invalid={invalid}
                    aria-describedby={describedBy}
                    autoCapitalize="characters"
                  />
                )}
              </FormField>
            </section>

            <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
              <FormField
                label="Price"
                hint="Enter the selling price in INR. Decimals are supported."
                error={errors.priceRupees}
                required
              >
                {({ id, describedBy, invalid }) => (
                  <Input
                    id={id}
                    required
                    inputMode="decimal"
                    value={form.priceRupees}
                    onChange={(event) => updateField("priceRupees", event.target.value.replace(/[^\d.]/g, ""))}
                    placeholder="799"
                    aria-invalid={invalid}
                    aria-describedby={describedBy}
                  />
                )}
              </FormField>

              <FormField
                label="Inventory"
                hint="Whole units currently available to sell."
                error={errors.inventoryCount}
                required
              >
                {({ id, describedBy, invalid }) => (
                  <Input
                    id={id}
                    required
                    inputMode="numeric"
                    value={form.inventoryCount}
                    onChange={(event) => updateField("inventoryCount", event.target.value.replace(/[^\d]/g, ""))}
                    placeholder="20"
                    aria-invalid={invalid}
                    aria-describedby={describedBy}
                  />
                )}
              </FormField>

              <FormField label="Currency" hint="Listings are locked to INR for consistency across the admin panel.">
                {({ id, describedBy }) => (
                  <div
                    id={id}
                    aria-describedby={describedBy}
                    className="flex h-11 items-center rounded-2xl border border-slate-200 bg-slate-50 px-3 text-sm text-slate-700"
                  >
                    INR (₹)
                  </div>
                )}
              </FormField>

              <FormField label="Status" hint="Draft keeps the listing private until you are ready to publish it.">
                {({ id, describedBy }) => (
                  <Select id={id} value={form.status} onChange={(event) => updateField("status", event.target.value)} aria-describedby={describedBy}>
                    {STATUS_OPTIONS.map((status) => (
                      <option key={status} value={status}>
                        {status}
                      </option>
                    ))}
                  </Select>
                )}
              </FormField>
            </section>

            <section className="space-y-2">
              <Text variant="kicker">Images</Text>
              <MediaUploadGrid
                marketplaceId={activeMarketplaceId}
                disabled={submitting || !activeMarketplaceId}
                slots={[
                  ...(!reuseProductId
                    ? [
                        {
                          key: "productImage",
                          label: "Product image",
                          hint: "Shared across listings that reuse this product.",
                          target: "product" as const,
                          value: form.productImage,
                          onChange: (asset: MediaAsset | null) => updateField("productImage", asset),
                        },
                      ]
                    : []),
                  {
                    key: "variantImage",
                    label: "Variant image",
                    hint: "Best for color-specific or size-specific visuals.",
                    target: "variant" as const,
                    value: form.variantImage,
                    onChange: (asset: MediaAsset | null) => updateField("variantImage", asset),
                  },
                  {
                    key: "listingImage",
                    label: "Listing image override",
                    hint: "This store-specific image overrides the variant and product images.",
                    target: "listing" as const,
                    value: form.listingImage,
                    onChange: (asset: MediaAsset | null) => updateField("listingImage", asset),
                  },
                ]}
              />
            </section>

            <div className="flex flex-col gap-3 sm:flex-row">
              <Button type="submit" variant="primary" disabled={submitting || !activeMarketplaceId || loadingMetadata}>
                {submitting ? "Saving..." : "Create listing"}
              </Button>
              <Button
                type="button"
                variant="secondary"
                disabled={submitting || !activeMarketplaceId || loadingMetadata}
                onClick={() => createListing(true).catch(() => null)}
              >
                Create new product anyway
              </Button>
            </div>
          </form>
        </Card>

        <Card className="bg-slate-50">
          <Text variant="kicker">Product reuse</Text>
          <Heading as="h2" size="h3" className="mt-2">
            Suggestions and sharing mode
          </Heading>
          <Text variant="muted" className="mt-2">
            {sharingCopy(sharingScope)}
          </Text>

          <div className="mt-6 rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-700">
            <p className="font-semibold text-slate-900">Current search</p>
            <p className="mt-1 text-slate-600">{suggestionQuery || "Start typing a product name or SKU to load suggestions."}</p>
          </div>

          <div className="mt-4 space-y-3">
            {sharingScope === "disabled" ? (
              <div className="rounded-2xl border border-dashed border-slate-300 bg-white px-4 py-6 text-sm text-slate-500">
                Product reuse is disabled in Settings, so no shared suggestions are shown here.
              </div>
            ) : suggestions.length === 0 ? (
              <div className="rounded-2xl border border-dashed border-slate-300 bg-white px-4 py-6 text-sm text-slate-500">
                No reusable products match the current product name or SKU yet.
              </div>
            ) : (
              suggestions.map((suggestion) => (
                <button
                  key={suggestion.product_id}
                  type="button"
                  onClick={() => chooseSuggestion(suggestion)}
                  className={`block w-full rounded-2xl border px-4 py-4 text-left transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-300 focus-visible:ring-offset-2 ${
                    reuseProductId === suggestion.product_id
                      ? "border-slate-950 bg-slate-950 text-white"
                      : "border-slate-200 bg-white text-slate-900 hover:border-slate-900"
                  }`}
                >
                  <p className="font-semibold">{suggestion.name}</p>
                  <p className="mt-1 text-sm opacity-80">{suggestion.sku}</p>
                  <p className="mt-2 text-xs opacity-75">
                    {[suggestion.product_type, suggestion.category].filter(Boolean).join(" • ") || "Existing catalog product"}
                  </p>
                </button>
              ))
            )}
          </div>
        </Card>
      </div>

      {listingsSwr.error ? (
        <Card className="border-rose-200 bg-rose-50 text-rose-900">
          <p className="text-sm font-semibold">Unable to load listings.</p>
        </Card>
      ) : null}

      {loading ? (
        <Table className="min-w-[56rem]">
          <thead>
            <tr>
              <Th>Product</Th>
              <Th>Status</Th>
              <Th>Price</Th>
              <Th>Inventory</Th>
              <Th>Updated</Th>
              <Th className="text-right">Actions</Th>
            </tr>
          </thead>
          <tbody>
            {Array.from({ length: 6 }).map((_, idx) => (
              <Tr key={idx}>
                <Td>
                  <div className="flex items-center gap-3">
                    <Skeleton className="h-12 w-12" />
                    <div className="space-y-2">
                      <Skeleton className="h-4 w-48" />
                      <Skeleton className="h-3 w-28" />
                    </div>
                  </div>
                </Td>
                <Td>
                  <Skeleton className="h-11 w-36" />
                </Td>
                <Td>
                  <Skeleton className="h-11 w-28" />
                </Td>
                <Td>
                  <Skeleton className="h-11 w-24" />
                </Td>
                <Td>
                  <Skeleton className="h-4 w-40" />
                </Td>
                <Td>
                  <div className="flex justify-end gap-2">
                    <Skeleton className="h-10 w-28" />
                  </div>
                </Td>
              </Tr>
            ))}
          </tbody>
        </Table>
      ) : (payload?.data ?? []).length ? (
        <Table className="min-w-[56rem]">
          <thead>
            <tr>
              <Th>Product</Th>
              <Th>Status</Th>
              <Th>Price</Th>
              <Th>Inventory</Th>
              <Th>Updated</Th>
              <Th className="text-right">Actions</Th>
            </tr>
          </thead>
          <tbody>
            {(payload?.data ?? []).map((listing) => (
              <Tr key={listing.id}>
                <Td className="min-w-[18rem]">
                  <div className="flex min-w-0 items-center gap-3">
                    <CloudinaryImage
                      asset={listing.image}
                      alt={listing.product.name}
                      className="h-12 w-12 shrink-0"
                      sizes="48px"
                      fallbackLabel="No image"
                    />
                    <div className="min-w-0">
                      <p className="truncate font-semibold text-slate-950">{listing.product.name}</p>
                      <p className="mt-1 text-xs font-semibold uppercase tracking-[0.18em] text-slate-500">{listing.product.sku}</p>
                      <p className="mt-1 text-xs text-slate-600">{listing.variant.name}</p>
                      {listing.image_source ? (
                        <p className="mt-2 text-[11px] font-semibold uppercase tracking-[0.18em] text-slate-400">
                          {listing.image_source} image
                        </p>
                      ) : null}
                    </div>
                  </div>
                </Td>
                <Td className="whitespace-nowrap">
                  <Select
                    aria-label="Status"
                    value={drafts[listing.id]?.status ?? listing.status ?? "active"}
                    onChange={(event) => updateDraft(listing.id, "status", event.target.value)}
                    disabled={mutatingListingId === listing.id}
                    className="min-w-[9rem]"
                  >
                    {STATUS_OPTIONS.map((status) => (
                      <option key={status} value={status}>
                        {status}
                      </option>
                    ))}
                  </Select>
                </Td>
                <Td className="whitespace-nowrap">
                  <Input
                    aria-label="Price"
                    inputMode="decimal"
                    value={drafts[listing.id]?.priceRupees ?? priceInputFromCents(listing.price_cents)}
                    onChange={(event) =>
                      updateDraft(listing.id, "priceRupees", event.target.value.replace(/[^\d.]/g, ""))
                    }
                    disabled={mutatingListingId === listing.id}
                    className="min-w-[7rem]"
                  />
                  <p className="mt-2 text-xs text-slate-500">{formatMoney(listing.price_cents, listing.currency)}</p>
                </Td>
                <Td className="whitespace-nowrap">
                  <Input
                    aria-label="Inventory"
                    inputMode="numeric"
                    value={drafts[listing.id]?.inventoryCount ?? String(listing.inventory_count)}
                    onChange={(event) =>
                      updateDraft(listing.id, "inventoryCount", event.target.value.replace(/[^\d]/g, ""))
                    }
                    disabled={mutatingListingId === listing.id}
                    className="min-w-[6rem]"
                  />
                  <p className="mt-2 text-xs text-slate-500">
                    {listing.inventory_count <= 0 ? "Out of stock" : `${listing.inventory_count} available`}
                  </p>
                </Td>
                <Td className="whitespace-nowrap text-sm text-slate-500">
                  {new Date(listing.updated_at).toLocaleString()}
                </Td>
                <Td className="whitespace-nowrap">
                  <div className="flex justify-end gap-2">
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
                      onClick={() => setDeleteTarget(listing)}
                      disabled={mutatingListingId === listing.id}
                    >
                      Delete
                    </Button>
                  </div>
                </Td>
              </Tr>
            ))}
          </tbody>
        </Table>
      ) : (
        <Card>
          <p className="text-center text-sm text-slate-600">No listings found for this store.</p>
        </Card>
      )}

      <ConfirmDialog
        open={Boolean(deleteTarget)}
        title="Delete listing?"
        description={
          deleteTarget
            ? `Delete ${deleteTarget.product.name} / ${deleteTarget.variant.name}. This removes it from the store and cannot be undone.`
            : undefined
        }
        confirmLabel="Delete listing"
        confirming={Boolean(deleteTarget && mutatingListingId === deleteTarget.id)}
        onConfirm={() => confirmDeleteTarget().catch(() => null)}
        onClose={() => setDeleteTarget(null)}
      />

      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
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
