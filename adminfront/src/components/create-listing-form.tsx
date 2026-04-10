"use client";

import { useEffect, useMemo, useState } from "react";
import { usePathname, useRouter } from "next/navigation";
import { clientApiFetch, ClientApiError } from "@/lib/client-api";
import { useToast } from "@/components/toast-provider";
import type { Category, PaginatedResponse, ProductSuggestion, ProductType } from "@/lib/types";

const DEFAULT_FORM = {
  productName: "",
  productSku: "",
  categoryId: "",
  productTypeId: "",
  variantName: "",
  variantSku: "",
  priceCents: "",
  currency: "USD",
  status: "draft",
};

function orgBaseFromPath(pathname: string): string {
  const segment = pathname.split("/")[1] ?? "";
  if (!segment) return "";
  if (segment === "api" || segment === "callback" || segment === "not-authorized") return "";
  return `/${segment}`;
}

export default function CreateListingForm() {
  const router = useRouter();
  const pathname = usePathname();
  const base = orgBaseFromPath(pathname);
  const { notify } = useToast();
  const [categories, setCategories] = useState<Category[]>([]);
  const [productTypes, setProductTypes] = useState<ProductType[]>([]);
  const [form, setForm] = useState(DEFAULT_FORM);
  const [reuseProductId, setReuseProductId] = useState<number | null>(null);
  const [suggestions, setSuggestions] = useState<ProductSuggestion[]>([]);
  const [submitting, setSubmitting] = useState(false);

  const suggestionQuery = useMemo(
    () => form.productName.trim() || form.productSku.trim(),
    [form.productName, form.productSku],
  );

  useEffect(() => {
    Promise.all([
      clientApiFetch<PaginatedResponse<Category>>("/v1/categories?per_page=100"),
      clientApiFetch<PaginatedResponse<ProductType>>("/v1/product_types?per_page=100"),
    ])
      .then(([categoryPayload, productTypePayload]) => {
        setCategories(categoryPayload.data);
        setProductTypes(productTypePayload.data);
      })
      .catch(() => null);
  }, []);

  useEffect(() => {
    if (!suggestionQuery) {
      setSuggestions([]);
      return;
    }

    const timer = window.setTimeout(() => {
      clientApiFetch<{ data: ProductSuggestion[] }>(
        `/v1/products/suggestions?q=${encodeURIComponent(suggestionQuery)}`,
      )
        .then((payload) => setSuggestions(payload.data))
        .catch(() => setSuggestions([]));
    }, 300);

    return () => window.clearTimeout(timer);
  }, [suggestionQuery]);

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

  async function submit(forceCreate = false) {
    setSubmitting(true);
    try {
      await clientApiFetch("/v1/listings", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          listing: {
            reuse_product_id: reuseProductId ?? undefined,
            force_create: forceCreate,
            price_cents: Number(form.priceCents),
            currency: form.currency,
            status: form.status,
            product: reuseProductId
              ? undefined
              : {
                  name: form.productName,
                  sku: form.productSku,
                  category_id: Number(form.categoryId),
                  product_type_id: Number(form.productTypeId),
                },
            variant: {
              name: form.variantName,
              sku: form.variantSku,
            },
          },
        }),
      });

      notify("Listing created", "success");
      router.replace(`${base}/listings`);
      router.refresh();
    } catch (error) {
      if (error instanceof ClientApiError && error.status === 409) {
        const nextSuggestions =
          (error.details as { meta?: { suggestions?: ProductSuggestion[] } } | undefined)?.meta?.suggestions ??
          [];
        setSuggestions(nextSuggestions);
        notify("Similar products found. Reuse one or create anyway.", "error");
      } else {
        notify(error instanceof Error ? error.message : "Failed to create listing", "error");
      }
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="grid gap-6 xl:grid-cols-[0.9fr_1.1fr]">
      <section className="rounded-[1.75rem] border border-slate-900/10 bg-slate-50 p-5">
        <p className="text-xs uppercase tracking-[0.25em] text-slate-500">Suggestions</p>
        <h2 className="mt-2 text-xl font-semibold text-slate-950">Reuse global products</h2>
        <div className="mt-5 space-y-3">
          {suggestions.length === 0 ? (
            <p className="rounded-2xl border border-dashed border-slate-300 px-4 py-6 text-sm text-slate-500">
              Start typing a product name or SKU to surface shared catalog matches.
            </p>
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
                <p className="font-medium">{suggestion.name}</p>
                <p className="mt-1 text-sm opacity-80">{suggestion.sku}</p>
              </button>
            ))
          )}
        </div>
      </section>

      <section className="rounded-[1.75rem] border border-slate-900/10 bg-white p-5">
        <p className="text-xs uppercase tracking-[0.25em] text-slate-500">Create listing</p>
        <h1 className="mt-2 text-2xl font-semibold tracking-tight text-slate-950">Publish inventory</h1>

        <form
          className="mt-6 space-y-4"
          onSubmit={(event) => {
            event.preventDefault();
            submit(false).catch(() => null);
          }}
        >
          <div className="grid gap-4 md:grid-cols-2">
            <input
              required
              value={form.productName}
              onChange={(event) => updateField("productName", event.target.value)}
              placeholder="Product name"
              className="rounded-2xl border border-slate-200 px-4 py-3 text-sm outline-none focus:border-slate-900"
            />
            <input
              required
              value={form.productSku}
              onChange={(event) => updateField("productSku", event.target.value)}
              placeholder="Product SKU"
              className="rounded-2xl border border-slate-200 px-4 py-3 text-sm outline-none focus:border-slate-900"
            />
          </div>

          {!reuseProductId ? (
            <div className="grid gap-4 md:grid-cols-2">
              <select
                required
                value={form.categoryId}
                onChange={(event) => updateField("categoryId", event.target.value)}
                className="rounded-2xl border border-slate-200 px-4 py-3 text-sm outline-none focus:border-slate-900"
              >
                <option value="">Category</option>
                {categories.map((category) => (
                  <option key={category.id} value={category.id}>
                    {category.name}
                  </option>
                ))}
              </select>
              <select
                required
                value={form.productTypeId}
                onChange={(event) => updateField("productTypeId", event.target.value)}
                className="rounded-2xl border border-slate-200 px-4 py-3 text-sm outline-none focus:border-slate-900"
              >
                <option value="">Product type</option>
                {productTypes.map((productType) => (
                  <option key={productType.id} value={productType.id}>
                    {productType.name}
                  </option>
                ))}
              </select>
            </div>
          ) : (
            <div className="rounded-2xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-900">
              Reusing shared product ID {reuseProductId}. Clear the name field to switch back to creating a new product.
            </div>
          )}

          <div className="grid gap-4 md:grid-cols-2">
            <input
              required
              value={form.variantName}
              onChange={(event) => updateField("variantName", event.target.value)}
              placeholder="Variant name"
              className="rounded-2xl border border-slate-200 px-4 py-3 text-sm outline-none focus:border-slate-900"
            />
            <input
              required
              value={form.variantSku}
              onChange={(event) => updateField("variantSku", event.target.value)}
              placeholder="Variant SKU"
              className="rounded-2xl border border-slate-200 px-4 py-3 text-sm outline-none focus:border-slate-900"
            />
          </div>

          <div className="grid gap-4 md:grid-cols-3">
            <input
              required
              value={form.priceCents}
              onChange={(event) => updateField("priceCents", event.target.value.replace(/[^\d]/g, ""))}
              placeholder="Price cents"
              className="rounded-2xl border border-slate-200 px-4 py-3 text-sm outline-none focus:border-slate-900"
            />
            <input
              required
              value={form.currency}
              onChange={(event) => updateField("currency", event.target.value.toUpperCase())}
              placeholder="Currency"
              className="rounded-2xl border border-slate-200 px-4 py-3 text-sm outline-none focus:border-slate-900"
            />
            <select
              value={form.status}
              onChange={(event) => updateField("status", event.target.value)}
              className="rounded-2xl border border-slate-200 px-4 py-3 text-sm outline-none focus:border-slate-900"
            >
              <option value="draft">Draft</option>
              <option value="active">Active</option>
              <option value="archived">Archived</option>
            </select>
          </div>

          <div className="flex flex-col gap-3 md:flex-row">
            <button disabled={submitting} className="rounded-full bg-slate-950 px-5 py-3 text-sm font-medium text-white disabled:opacity-60">
              {submitting ? "Saving..." : "Create listing"}
            </button>
            <button
              type="button"
              disabled={submitting}
              onClick={() => submit(true)}
              className="rounded-full border border-slate-300 px-5 py-3 text-sm font-medium text-slate-700 disabled:opacity-60"
            >
              Create new product anyway
            </button>
          </div>
        </form>
      </section>
    </div>
  );
}

