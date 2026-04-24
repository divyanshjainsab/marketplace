"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { CloudinaryImage } from "@/components/media/cloudinary-image";
import { useCart } from "@/components/cart/cart-provider";
import { useToast } from "@/components/toast-provider";
import { cn } from "@/lib/cn";
import { formatInrFromCents } from "@/lib/currency";
import type { Listing, Product, Variant } from "@/lib/types";

type Props = {
  product: Product;
  listings: Listing[];
  initialVariantId: number | null;
};

function optionKeysFor(variants: Variant[]) {
  const keys = Array.from(new Set(variants.flatMap((variant) => Object.keys(variant.options || {}))));
  const priority = ["size", "color", "fabric"];
  return keys.sort((a, b) => {
    const ai = priority.indexOf(a);
    const bi = priority.indexOf(b);
    if (ai !== -1 || bi !== -1) return (ai === -1 ? 999 : ai) - (bi === -1 ? 999 : bi);
    return a.localeCompare(b);
  });
}

export default function ProductDetail({ product, listings, initialVariantId }: Props) {
  const variants = product.variants ?? [];
  const optionKeys = useMemo(() => optionKeysFor(variants), [variants]);
  const { addItem } = useCart();
  const { notify } = useToast();

  const listingByVariantId = useMemo(() => {
    const map = new Map<number, Listing>();
    listings.forEach((listing) => {
      map.set(listing.variant.id, listing);
    });
    return map;
  }, [listings]);

  const [selected, setSelected] = useState<Record<string, string>>({});

  useEffect(() => {
    if (!initialVariantId) return;
    const variant = variants.find((v) => v.id === initialVariantId);
    if (!variant) return;
    setSelected(variant.options || {});
  }, [initialVariantId, variants]);

  const matchingVariants = useMemo(() => {
    const entries = Object.entries(selected).filter(([, value]) => value);
    if (entries.length === 0) return variants;
    return variants.filter((variant) => entries.every(([key, value]) => (variant.options || {})[key] === value));
  }, [selected, variants]);

  const resolvedVariant = useMemo(() => {
    if (matchingVariants.length === 1) return matchingVariants[0];
    return null;
  }, [matchingVariants]);

  const resolvedListing = resolvedVariant ? listingByVariantId.get(resolvedVariant.id) ?? null : null;
  const imageAsset = resolvedListing?.image ?? resolvedVariant?.image ?? product.image ?? null;
  const inventory = resolvedListing?.inventory_count ?? null;
  const outOfStock = inventory != null && inventory <= 0;

  function valuesForKey(key: string) {
    return Array.from(new Set(variants.map((variant) => (variant.options || {})[key]).filter(Boolean))).sort();
  }

  function valueIsSelectable(key: string, value: string) {
    const others = Object.entries(selected).filter(([k, v]) => k !== key && v);
    const candidates = variants.filter((variant) => {
      const options = variant.options || {};
      if (options[key] !== value) return false;
      return others.every(([k, v]) => options[k] === v);
    });
    if (candidates.length === 0) return false;
    return candidates.some((variant) => {
      const listing = listingByVariantId.get(variant.id);
      return listing && listing.inventory_count > 0;
    });
  }

  return (
    <div className="grid gap-10 lg:grid-cols-[1.05fr_0.95fr]">
      <section className="space-y-4">
        <Link href="/products" className="text-sm font-semibold text-stone-700 hover:text-stone-900">
          ← Back to products
        </Link>

        <CloudinaryImage
          asset={imageAsset}
          alt={product.name}
          className="h-[22rem] w-full md:h-[28rem]"
          fill
          priority
          sizes="(min-width: 1024px) 42rem, 100vw"
          fallbackLabel="No image"
        />
      </section>

      <section className="space-y-6">
        <div>
          <p className="text-xs uppercase tracking-[0.3em] text-stone-500">{product.category?.name}</p>
          <h1 className="mt-2 text-balance text-3xl font-semibold tracking-tight md:text-4xl">{product.name}</h1>
          <p className="mt-3 text-sm text-stone-600">SKU {product.sku}</p>
        </div>

        <div className="rounded-3xl border border-stone-900/10 bg-stone-50 p-5">
          <p className="text-xs uppercase tracking-[0.25em] text-stone-500">Price</p>
          <p className="mt-2 text-2xl font-semibold text-stone-900">
            {formatInrFromCents(resolvedListing?.price_cents ?? null)}
          </p>
          <p className="mt-2 text-sm text-stone-600">
            {resolvedVariant
              ? resolvedListing
                ? outOfStock
                  ? "Out of stock"
                  : `${inventory} in stock`
                : "Not listed in this marketplace"
              : "Select options to see availability"}
          </p>
        </div>

        {optionKeys.length > 0 ? (
          <div className="space-y-5">
            {optionKeys.map((key) => {
              const values = valuesForKey(key);
              if (values.length === 0) return null;

              return (
                <div key={key}>
                  <p className="text-xs font-semibold uppercase tracking-[0.25em] text-stone-500">{key}</p>
                  <div className="mt-3 flex flex-wrap gap-2">
                    {values.map((value) => {
                      const selectedValue = selected[key] === value;
                      const selectable = valueIsSelectable(key, value);
                      return (
                        <button
                          key={value}
                          type="button"
                          disabled={!selectable}
                          onClick={() =>
                            setSelected((current) => ({
                              ...current,
                              [key]: current[key] === value ? "" : value,
                            }))
                          }
                          className={cn(
                            "rounded-full border px-4 py-2 text-sm font-semibold transition",
                            selectedValue
                              ? "border-stone-900 bg-stone-900 text-stone-50"
                              : "border-stone-200 bg-white text-stone-800 hover:border-stone-300",
                            !selectable ? "cursor-not-allowed opacity-40 hover:border-stone-200" : "",
                          )}
                        >
                          {value}
                        </button>
                      );
                    })}
                  </div>
                </div>
              );
            })}
          </div>
        ) : null}

        <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
          <button
            type="button"
            disabled={!resolvedVariant || !resolvedListing || outOfStock}
            onClick={() => {
              if (!resolvedVariant) {
                notify("Select a variant first.", "error");
                return;
              }
              if (!resolvedListing) {
                notify("This variant is not listed in this marketplace.", "error");
                return;
              }
              if (outOfStock) {
                notify("This variant is out of stock.", "error");
                return;
              }

              addItem(resolvedVariant.id, 1)
                .then(() => notify("Added to cart", "success"))
                .catch((err) => notify(err instanceof Error ? err.message : "Unable to add to cart", "error"));
            }}
            className="inline-flex items-center justify-center rounded-2xl bg-stone-900 px-6 py-3 text-sm font-semibold text-stone-50 shadow-sm hover:bg-stone-800 disabled:cursor-not-allowed disabled:opacity-60"
          >
            Add to cart
          </button>

          <Link
            href="/cart"
            className="inline-flex items-center justify-center rounded-2xl border border-stone-200 bg-white px-6 py-3 text-sm font-semibold text-stone-800 hover:border-stone-300"
          >
            View cart
          </Link>
        </div>

        {Object.keys(product.metadata || {}).length > 0 ? (
          <div className="rounded-3xl border border-stone-900/10 bg-white p-5">
            <p className="text-xs font-semibold uppercase tracking-[0.25em] text-stone-500">Details</p>
            <dl className="mt-4 grid gap-3 sm:grid-cols-2">
              {Object.entries(product.metadata || {}).map(([key, value]) => (
                <div key={key} className="rounded-2xl border border-stone-200 bg-stone-50 px-4 py-3">
                  <dt className="text-[11px] font-semibold uppercase tracking-[0.18em] text-stone-500">{key}</dt>
                  <dd className="mt-1 text-sm font-medium text-stone-900">{String(value)}</dd>
                </div>
              ))}
            </dl>
          </div>
        ) : null}
      </section>
    </div>
  );
}

