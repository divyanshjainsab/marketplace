"use client";

import Link from "next/link";
import { CloudinaryImage } from "@/components/media/cloudinary-image";
import { useCart } from "@/components/cart/cart-provider";
import { useToast } from "@/components/toast-provider";
import { formatInrFromCents } from "@/lib/currency";

export default function CartPage() {
  const { cart, loading, removeItem, setQuantity } = useCart();
  const { notify } = useToast();

  const items = cart?.items ?? [];

  return (
    <main className="px-4 py-8 md:px-6">
      <div className="mx-auto max-w-5xl rounded-[2rem] border border-stone-900/10 bg-white/75 p-6 shadow-[0_24px_80px_rgba(83,58,21,0.12)] backdrop-blur md:p-8">
        <div className="flex flex-col gap-2 md:flex-row md:items-end md:justify-between">
          <div>
            <p className="text-xs uppercase tracking-[0.3em] text-stone-500">Storefront</p>
            <h1 className="mt-2 text-3xl font-semibold tracking-tight md:text-4xl">Your cart</h1>
            <p className="mt-2 text-sm text-stone-600">Cart persists on refresh for this marketplace.</p>
          </div>
          <Link href="/products" className="text-sm font-semibold text-stone-700 hover:text-stone-900">
            Continue shopping →
          </Link>
        </div>

        {loading ? (
          <div className="mt-8 animate-pulse space-y-4">
            <div className="h-24 rounded-3xl bg-stone-100" />
            <div className="h-24 rounded-3xl bg-stone-100" />
            <div className="h-24 rounded-3xl bg-stone-100" />
          </div>
        ) : items.length === 0 ? (
          <div className="mt-8 rounded-3xl border border-stone-200 bg-stone-50 p-6">
            <p className="text-sm font-medium text-stone-900">Your cart is empty.</p>
            <p className="mt-2 text-sm text-stone-600">Browse listings and add a variant to get started.</p>
            <Link
              href="/products"
              className="mt-5 inline-flex items-center justify-center rounded-full bg-stone-900 px-5 py-2.5 text-sm font-semibold text-stone-50 hover:bg-stone-800"
            >
              Browse products
            </Link>
          </div>
        ) : (
          <div className="mt-8 grid gap-6 lg:grid-cols-[1fr_18rem]">
            <section className="space-y-4">
              {items.map((item) => {
                const listing = item.listing;
                const name = listing?.product.name ?? "Unavailable product";
                const variantName = listing?.variant.name ?? "Unavailable variant";
                const inventory = item.inventory_count ?? listing?.inventory_count ?? null;

                return (
                  <article
                    key={item.variant_id}
                    className="grid gap-4 rounded-3xl border border-stone-900/10 bg-white p-4 shadow-sm sm:grid-cols-[7rem_1fr]"
                  >
                    <CloudinaryImage
                      asset={listing?.image}
                      alt={name}
                      className="h-28 w-full sm:h-28"
                      fill
                      sizes="(min-width: 640px) 7rem, 100vw"
                      fallbackLabel="No image"
                    />

                    <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
                      <div>
                        <p className="text-sm font-semibold text-stone-900">{name}</p>
                        <p className="mt-1 text-sm text-stone-500">{variantName}</p>
                        <p className="mt-3 text-sm font-semibold text-stone-900">{formatInrFromCents(item.unit_price_cents)}</p>
                        {inventory != null ? (
                          <p className="mt-2 text-xs text-stone-500">
                            {inventory <= 0 ? "Out of stock" : `${inventory} in stock`}
                          </p>
                        ) : null}
                      </div>

                      <div className="flex items-center gap-3">
                        <div className="inline-flex items-center rounded-full border border-stone-200 bg-white">
                          <button
                            type="button"
                            onClick={() => {
                              const next = Math.max(item.quantity - 1, 1);
                              setQuantity(item.variant_id, next).catch((err) => {
                                notify(err instanceof Error ? err.message : "Unable to update cart", "error");
                              });
                            }}
                            disabled={item.quantity <= 1}
                            className="h-9 w-9 rounded-full text-stone-700 disabled:opacity-40"
                            aria-label="Decrease quantity"
                          >
                            −
                          </button>
                          <span className="w-10 text-center text-sm font-semibold text-stone-900">{item.quantity}</span>
                          <button
                            type="button"
                            onClick={() => {
                              const next = item.quantity + 1;
                              setQuantity(item.variant_id, next).catch((err) => {
                                notify(err instanceof Error ? err.message : "Unable to update cart", "error");
                              });
                            }}
                            disabled={inventory != null ? item.quantity >= inventory : false}
                            className="h-9 w-9 rounded-full text-stone-700 disabled:opacity-40"
                            aria-label="Increase quantity"
                          >
                            +
                          </button>
                        </div>

                        <button
                          type="button"
                          onClick={() => {
                            removeItem(item.variant_id)
                              .then(() => notify("Removed from cart", "success"))
                              .catch((err) => notify(err instanceof Error ? err.message : "Unable to remove item", "error"));
                          }}
                          className="rounded-full border border-stone-200 bg-white px-3 py-2 text-xs font-semibold text-stone-700 hover:border-stone-300 hover:text-stone-900"
                        >
                          Remove
                        </button>
                      </div>
                    </div>
                  </article>
                );
              })}
            </section>

            <aside className="h-fit rounded-3xl border border-stone-900/10 bg-stone-50 p-5">
              <h2 className="text-sm font-semibold text-stone-900">Summary</h2>
              <div className="mt-4 space-y-2 text-sm text-stone-700">
                <div className="flex items-center justify-between">
                  <span>Items</span>
                  <span className="font-medium text-stone-900">{cart?.item_count ?? 0}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span>Subtotal</span>
                  <span className="font-medium text-stone-900">{formatInrFromCents(cart?.subtotal_cents ?? 0)}</span>
                </div>
              </div>
              <button
                type="button"
                className="mt-6 w-full rounded-2xl bg-stone-900 px-5 py-3 text-sm font-semibold text-stone-50 shadow-sm hover:bg-stone-800"
                onClick={() => notify("Checkout is not implemented yet.", "default")}
              >
                Checkout
              </button>
              <p className="mt-3 text-xs text-stone-500">
                Pricing and inventory are validated server-side. Your cart will revalidate on every update.
              </p>
            </aside>
          </div>
        )}
      </div>
    </main>
  );
}

