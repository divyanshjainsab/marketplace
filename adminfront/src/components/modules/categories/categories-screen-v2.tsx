"use client";

import { useMemo, useState } from "react";
import useSWR from "swr";
import { ClientApiError, clientApiFetch } from "@/lib/client-api";
import type { Category, PaginatedResponse, ProductType } from "@/lib/types";
import { useWorkspace } from "@/components/providers/workspace-provider";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Select } from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";

type CategoryFormState = {
  name: string;
  code: string;
  parentId: string;
};

type ProductTypeFormState = {
  name: string;
  code: string;
};

const DEFAULT_CATEGORY_FORM: CategoryFormState = {
  name: "",
  code: "",
  parentId: "",
};

const DEFAULT_PRODUCT_TYPE_FORM: ProductTypeFormState = {
  name: "",
  code: "",
};

function Field({
  label,
  hint,
  error,
  children,
}: React.PropsWithChildren<{ label: string; hint?: string; error?: string }>) {
  return (
    <label className="block space-y-2">
      <span className="block text-sm font-semibold text-slate-900">{label}</span>
      {children}
      {hint ? <span className="block text-xs leading-5 text-slate-500">{hint}</span> : null}
      {error ? <span className="block text-sm text-rose-700">{error}</span> : null}
    </label>
  );
}

export function CategoriesScreenV2() {
  const { activeMarketplaceId, activeMarketplace, loading: workspaceLoading, permissions } = useWorkspace();
  const [categoryForm, setCategoryForm] = useState(DEFAULT_CATEGORY_FORM);
  const [productTypeForm, setProductTypeForm] = useState(DEFAULT_PRODUCT_TYPE_FORM);
  const [categoryErrors, setCategoryErrors] = useState<Record<string, string>>({});
  const [productTypeErrors, setProductTypeErrors] = useState<Record<string, string>>({});
  const [submittingCategory, setSubmittingCategory] = useState(false);
  const [submittingProductType, setSubmittingProductType] = useState(false);

  const canEditCategories = permissions.includes("edit_categories");
  const canEditProductTypes = permissions.includes("edit_product_types");

  const categoriesKey = useMemo(() => {
    if (!activeMarketplaceId) return null;
    return `/v1/admin/categories?marketplace_id=${activeMarketplaceId}&per_page=200`;
  }, [activeMarketplaceId]);

  const productTypesKey = useMemo(() => {
    if (!activeMarketplaceId) return null;
    return `/v1/admin/product_types?marketplace_id=${activeMarketplaceId}&per_page=200`;
  }, [activeMarketplaceId]);

  const categoriesSwr = useSWR<PaginatedResponse<Category>>(categoriesKey, (path: string) => clientApiFetch<PaginatedResponse<Category>>(path));
  const productTypesSwr = useSWR<PaginatedResponse<ProductType>>(productTypesKey, (path: string) => clientApiFetch<PaginatedResponse<ProductType>>(path));

  const categories = categoriesSwr.data?.data ?? [];
  const productTypes = productTypesSwr.data?.data ?? [];
  const loading = workspaceLoading || categoriesSwr.isLoading || productTypesSwr.isLoading;

  async function createCategory() {
    if (!activeMarketplaceId) return;

    const nextErrors: Record<string, string> = {};
    if (!categoryForm.name.trim()) nextErrors.name = "Enter a category name.";

    setCategoryErrors(nextErrors);
    if (Object.keys(nextErrors).length) return;

    setSubmittingCategory(true);

    try {
      await clientApiFetch(`/v1/admin/categories?marketplace_id=${activeMarketplaceId}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          category: {
            name: categoryForm.name.trim(),
            code: categoryForm.code.trim() || undefined,
            parent_id: categoryForm.parentId ? Number(categoryForm.parentId) : undefined,
          },
        }),
      });

      setCategoryForm(DEFAULT_CATEGORY_FORM);
      setCategoryErrors({});
      await categoriesSwr.mutate();
    } catch (error) {
      if (error instanceof ClientApiError) {
        const details = (error.details as { error?: { details?: Record<string, string[] | string> } } | undefined)?.error?.details;
        setCategoryErrors({
          name: Array.isArray(details?.name) ? details?.name[0] : "",
          code: Array.isArray(details?.code) ? details?.code[0] : "",
          parentId: Array.isArray(details?.parent_id) ? details?.parent_id[0] : "",
          form: error.message,
        });
      } else {
        setCategoryErrors({ form: error instanceof Error ? error.message : "Unable to create category" });
      }
    } finally {
      setSubmittingCategory(false);
    }
  }

  async function createProductType() {
    if (!activeMarketplaceId) return;

    const nextErrors: Record<string, string> = {};
    if (!productTypeForm.name.trim()) nextErrors.name = "Enter a product type name.";

    setProductTypeErrors(nextErrors);
    if (Object.keys(nextErrors).length) return;

    setSubmittingProductType(true);

    try {
      await clientApiFetch(`/v1/admin/product_types?marketplace_id=${activeMarketplaceId}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          product_type: {
            name: productTypeForm.name.trim(),
            code: productTypeForm.code.trim() || undefined,
          },
        }),
      });

      setProductTypeForm(DEFAULT_PRODUCT_TYPE_FORM);
      setProductTypeErrors({});
      await productTypesSwr.mutate();
    } catch (error) {
      if (error instanceof ClientApiError) {
        const details = (error.details as { error?: { details?: Record<string, string[] | string> } } | undefined)?.error?.details;
        setProductTypeErrors({
          name: Array.isArray(details?.name) ? details?.name[0] : "",
          code: Array.isArray(details?.code) ? details?.code[0] : "",
          form: error.message,
        });
      } else {
        setProductTypeErrors({ form: error instanceof Error ? error.message : "Unable to create product type" });
      }
    } finally {
      setSubmittingProductType(false);
    }
  }

  return (
    <div className="space-y-5">
      <Card className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
        <div>
          <p className="text-xs uppercase tracking-[0.25em] text-slate-500">Catalog setup</p>
          <h1 className="mt-2 text-2xl font-semibold tracking-tight text-slate-950">Categories and product types</h1>
          <p className="mt-2 max-w-2xl text-sm text-slate-600">
            {activeMarketplace?.name ? `Manage the taxonomy powering ${activeMarketplace.name}.` : "Manage the taxonomy powering your store."}
          </p>
        </div>
        <Button variant="secondary" onClick={() => Promise.all([categoriesSwr.mutate(), productTypesSwr.mutate()])} disabled={loading}>
          Refresh catalog data
        </Button>
      </Card>

      <div className="grid gap-5 xl:grid-cols-2">
        <Card>
          <p className="text-xs uppercase tracking-[0.25em] text-slate-500">Create category</p>
          <h2 className="mt-2 text-xl font-semibold tracking-tight text-slate-950">Add a category</h2>
          <p className="mt-2 text-sm text-slate-600">Create browseable categories so the listing form stays usable end to end.</p>

          {categoryErrors.form ? (
            <div className="mt-4 rounded-2xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-900">{categoryErrors.form}</div>
          ) : null}

          <div className="mt-5 space-y-4">
            <Field
              label="Category name"
              hint="Shown to admins now and available for storefront merchandising later."
              error={categoryErrors.name}
            >
              <Input
                value={categoryForm.name}
                onChange={(event) => {
                  setCategoryErrors((current) => ({ ...current, name: "", form: "" }));
                  setCategoryForm((current) => ({ ...current, name: event.target.value }));
                }}
                placeholder="T-Shirts"
                disabled={!activeMarketplaceId || !canEditCategories || submittingCategory}
              />
            </Field>

            <Field
              label="Category code"
              hint="Optional. Leave blank to auto-generate a stable code from the name."
              error={categoryErrors.code}
            >
              <Input
                value={categoryForm.code}
                onChange={(event) => {
                  setCategoryErrors((current) => ({ ...current, code: "", form: "" }));
                  setCategoryForm((current) => ({ ...current, code: event.target.value }));
                }}
                placeholder="t_shirts"
                disabled={!activeMarketplaceId || !canEditCategories || submittingCategory}
              />
            </Field>

            <Field
              label="Parent category"
              hint="Optional. Use this when you want a category to sit underneath another one."
              error={categoryErrors.parentId}
            >
              <Select
                value={categoryForm.parentId}
                onChange={(event) => setCategoryForm((current) => ({ ...current, parentId: event.target.value }))}
                disabled={!activeMarketplaceId || !canEditCategories || submittingCategory}
              >
                <option value="">No parent category</option>
                {categories.map((category) => (
                  <option key={category.id} value={category.id}>
                    {category.name}
                  </option>
                ))}
              </Select>
            </Field>

            <Button type="button" variant="primary" className="w-full sm:w-auto" onClick={() => createCategory().catch(() => null)} disabled={!activeMarketplaceId || !canEditCategories || submittingCategory}>
              {submittingCategory ? "Saving..." : "Create category"}
            </Button>
          </div>
        </Card>

        <Card>
          <p className="text-xs uppercase tracking-[0.25em] text-slate-500">Create product type</p>
          <h2 className="mt-2 text-xl font-semibold tracking-tight text-slate-950">Add a product type</h2>
          <p className="mt-2 text-sm text-slate-600">Product types power reporting, search filters, and the listing form’s required structure.</p>

          {productTypeErrors.form ? (
            <div className="mt-4 rounded-2xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-900">{productTypeErrors.form}</div>
          ) : null}

          <div className="mt-5 space-y-4">
            <Field
              label="Product type name"
              hint="Examples: Clothing, Electronics, Grocery."
              error={productTypeErrors.name}
            >
              <Input
                value={productTypeForm.name}
                onChange={(event) => {
                  setProductTypeErrors((current) => ({ ...current, name: "", form: "" }));
                  setProductTypeForm((current) => ({ ...current, name: event.target.value }));
                }}
                placeholder="Clothing"
                disabled={!activeMarketplaceId || !canEditProductTypes || submittingProductType}
              />
            </Field>

            <Field
              label="Product type code"
              hint="Optional. Leave blank to auto-generate a stable code from the name."
              error={productTypeErrors.code}
            >
              <Input
                value={productTypeForm.code}
                onChange={(event) => {
                  setProductTypeErrors((current) => ({ ...current, code: "", form: "" }));
                  setProductTypeForm((current) => ({ ...current, code: event.target.value }));
                }}
                placeholder="clothing"
                disabled={!activeMarketplaceId || !canEditProductTypes || submittingProductType}
              />
            </Field>

            <Button type="button" variant="primary" className="w-full sm:w-auto" onClick={() => createProductType().catch(() => null)} disabled={!activeMarketplaceId || !canEditProductTypes || submittingProductType}>
              {submittingProductType ? "Saving..." : "Create product type"}
            </Button>
          </div>
        </Card>
      </div>

      <div className="grid gap-5 xl:grid-cols-2">
        <Card>
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs uppercase tracking-[0.25em] text-slate-500">Current categories</p>
              <h2 className="mt-2 text-xl font-semibold tracking-tight text-slate-950">Available categories</h2>
            </div>
            <p className="text-sm text-slate-500">{categories.length} total</p>
          </div>

          <div className="mt-5 grid gap-3">
            {loading ? (
              Array.from({ length: 5 }).map((_, idx) => <Skeleton key={idx} className="h-20 w-full rounded-2xl" />)
            ) : categories.length ? (
              categories.map((category) => {
                const parent = categories.find((candidate) => candidate.id === category.parent_id);
                return (
                  <div key={category.id} className="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-4">
                    <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
                      <div>
                        <p className="font-semibold text-slate-950">{category.name}</p>
                        <p className="mt-1 text-xs uppercase tracking-[0.18em] text-slate-500">{category.code}</p>
                        <p className="mt-2 text-sm text-slate-600">{parent ? `Parent: ${parent.name}` : "Top-level category"}</p>
                      </div>
                      <p className="text-sm font-medium text-slate-700">{category.product_count ?? 0} products</p>
                    </div>
                  </div>
                );
              })
            ) : (
              <div className="rounded-2xl border border-dashed border-slate-300 bg-slate-50 px-4 py-6 text-sm text-slate-500">
                No categories exist yet for this organization.
              </div>
            )}
          </div>
        </Card>

        <Card>
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs uppercase tracking-[0.25em] text-slate-500">Current product types</p>
              <h2 className="mt-2 text-xl font-semibold tracking-tight text-slate-950">Available product types</h2>
            </div>
            <p className="text-sm text-slate-500">{productTypes.length} total</p>
          </div>

          <div className="mt-5 grid gap-3">
            {loading ? (
              Array.from({ length: 4 }).map((_, idx) => <Skeleton key={idx} className="h-20 w-full rounded-2xl" />)
            ) : productTypes.length ? (
              productTypes.map((productType) => (
                <div key={productType.id} className="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-4">
                  <div className="flex items-center justify-between gap-3">
                    <div>
                      <p className="font-semibold text-slate-950">{productType.name}</p>
                      <p className="mt-1 text-xs uppercase tracking-[0.18em] text-slate-500">{productType.code}</p>
                    </div>
                    <p className="text-sm font-medium text-slate-700">{productType.product_count ?? 0} products</p>
                  </div>
                </div>
              ))
            ) : (
              <div className="rounded-2xl border border-dashed border-slate-300 bg-slate-50 px-4 py-6 text-sm text-slate-500">
                No product types exist yet for this organization.
              </div>
            )}
          </div>
        </Card>
      </div>
    </div>
  );
}
