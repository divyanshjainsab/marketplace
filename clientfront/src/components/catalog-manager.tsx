"use client";

import { useCallback, useEffect, useState } from "react";
import { clientApiFetch } from "@/lib/client-api";
import { useToast } from "@/components/toast-provider";
import type { Category, PaginatedResponse, Product, ProductType } from "@/lib/types";

export default function CatalogManager() {
  const { notify } = useToast();
  const [products, setProducts] = useState<PaginatedResponse<Product> | null>(null);
  const [categories, setCategories] = useState<Category[]>([]);
  const [productTypes, setProductTypes] = useState<ProductType[]>([]);
  const [query, setQuery] = useState("");
  const [form, setForm] = useState({
    name: "",
    sku: "",
    category_id: "",
    product_type_id: "",
  });

  const refreshProducts = useCallback(async (search = query) => {
    const params = new URLSearchParams({ per_page: "12" });
    if (search.trim()) params.set("q", search.trim());
    const payload = await clientApiFetch<PaginatedResponse<Product>>(`/v1/products?${params.toString()}`);
    setProducts(payload);
  }, [query]);

  useEffect(() => {
    Promise.all([
      refreshProducts(),
      clientApiFetch<PaginatedResponse<Category>>("/v1/categories?per_page=100"),
      clientApiFetch<PaginatedResponse<ProductType>>("/v1/product_types?per_page=100"),
    ]).then(([, categoryPayload, productTypePayload]) => {
      setCategories(categoryPayload.data);
      setProductTypes(productTypePayload.data);
    }).catch(() => null);
  }, [refreshProducts]);

  async function handleCreate(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    try {
      await clientApiFetch("/v1/products", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          product: {
            ...form,
            category_id: Number(form.category_id),
            product_type_id: Number(form.product_type_id),
            metadata: {},
          },
        }),
      });
      notify("Product saved", "success");
      setForm({ name: "", sku: "", category_id: "", product_type_id: "" });
      await refreshProducts("");
    } catch (error) {
      notify(error instanceof Error ? error.message : "Failed to save product", "error");
    }
  }

  return (
    <div className="grid gap-6 xl:grid-cols-[1.2fr_0.8fr]">
      <section className="rounded-[1.75rem] border border-stone-900/10 bg-white p-5">
        <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
          <div>
            <p className="text-xs uppercase tracking-[0.25em] text-stone-500">Global catalog</p>
            <h1 className="mt-2 text-2xl font-semibold tracking-tight text-stone-950">Products</h1>
          </div>
          <input
            value={query}
            onChange={(event) => {
              setQuery(event.target.value);
              refreshProducts(event.target.value).catch(() => null);
            }}
            placeholder="Search products"
            className="w-full rounded-2xl border border-stone-200 px-4 py-3 text-sm outline-none focus:border-stone-900 md:max-w-sm"
          />
        </div>

        <div className="mt-5 overflow-hidden rounded-3xl border border-stone-200">
          <table className="min-w-full divide-y divide-stone-200 text-left text-sm">
            <thead className="bg-stone-50 text-stone-500">
              <tr>
                <th className="px-4 py-3 font-medium">Name</th>
                <th className="px-4 py-3 font-medium">SKU</th>
                <th className="px-4 py-3 font-medium">Category</th>
                <th className="px-4 py-3 font-medium">Type</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-stone-100 bg-white">
              {(products?.data ?? []).map((product) => (
                <tr key={product.id}>
                  <td className="px-4 py-3 font-medium text-stone-900">{product.name}</td>
                  <td className="px-4 py-3 text-stone-600">{product.sku}</td>
                  <td className="px-4 py-3 text-stone-600">{product.category.name}</td>
                  <td className="px-4 py-3 text-stone-600">{product.product_type.name}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      <section className="rounded-[1.75rem] border border-stone-900/10 bg-stone-50 p-5">
        <p className="text-xs uppercase tracking-[0.25em] text-stone-500">Create product</p>
        <h2 className="mt-2 text-xl font-semibold text-stone-950">Add to the shared catalog</h2>

        <form onSubmit={handleCreate} className="mt-5 space-y-4">
          <input
            required
            value={form.name}
            onChange={(event) => setForm((current) => ({ ...current, name: event.target.value }))}
            placeholder="Product name"
            className="w-full rounded-2xl border border-stone-200 px-4 py-3 text-sm outline-none focus:border-stone-900"
          />
          <input
            required
            value={form.sku}
            onChange={(event) => setForm((current) => ({ ...current, sku: event.target.value }))}
            placeholder="SKU"
            className="w-full rounded-2xl border border-stone-200 px-4 py-3 text-sm outline-none focus:border-stone-900"
          />
          <select
            required
            value={form.category_id}
            onChange={(event) => setForm((current) => ({ ...current, category_id: event.target.value }))}
            className="w-full rounded-2xl border border-stone-200 px-4 py-3 text-sm outline-none focus:border-stone-900"
          >
            <option value="">Select category</option>
            {categories.map((category) => (
              <option key={category.id} value={category.id}>
                {category.name}
              </option>
            ))}
          </select>
          <select
            required
            value={form.product_type_id}
            onChange={(event) => setForm((current) => ({ ...current, product_type_id: event.target.value }))}
            className="w-full rounded-2xl border border-stone-200 px-4 py-3 text-sm outline-none focus:border-stone-900"
          >
            <option value="">Select product type</option>
            {productTypes.map((productType) => (
              <option key={productType.id} value={productType.id}>
                {productType.name}
              </option>
            ))}
          </select>
          <button className="w-full rounded-full bg-stone-950 px-5 py-3 text-sm font-medium text-white">
            Save product
          </button>
        </form>
      </section>
    </div>
  );
}
