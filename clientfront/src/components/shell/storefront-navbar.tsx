"use client";

import Link from "next/link";
import { useEffect, useMemo, useRef, useState } from "react";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { clientApiFetch } from "@/lib/client-api";
import { cn } from "@/lib/cn";
import { formatInrFromCents } from "@/lib/currency";
import type { Listing, PaginatedResponse, SessionResponse } from "@/lib/types";
import { useCart } from "@/components/cart/cart-provider";

type Suggestion = {
  key: string;
  href: string;
  title: string;
  subtitle: string;
  priceLabel: string | null;
};

function cartCountLabel(count: number) {
  if (count <= 0) return "0";
  if (count > 99) return "99+";
  return String(count);
}

export function StorefrontNavbar() {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const { cart } = useCart();

  const [session, setSession] = useState<SessionResponse | null>(null);
  const [query, setQuery] = useState("");
  const [suggestions, setSuggestions] = useState<Suggestion[]>([]);
  const [suggestionsOpen, setSuggestionsOpen] = useState(false);
  const [searching, setSearching] = useState(false);
  const searchRef = useRef<HTMLDivElement | null>(null);

  const returnTo = useMemo(() => {
    const current = `${pathname}${searchParams?.toString() ? `?${searchParams.toString()}` : ""}`;
    return encodeURIComponent(current);
  }, [pathname, searchParams]);

  useEffect(() => {
    clientApiFetch<SessionResponse>("/v1/session")
      .then((payload) => setSession(payload))
      .catch(() => setSession({ data: { user: null, marketplace: null } }));
  }, []);

  useEffect(() => {
    let active = true;
    setSearching(true);

    const timer = window.setTimeout(() => {
      const trimmed = query.trim();
      if (trimmed.length < 2) {
        if (active) {
          setSuggestions([]);
          setSuggestionsOpen(false);
          setSearching(false);
        }
        return;
      }

      const params = new URLSearchParams({ q: trimmed, page: "1", per_page: "5" });
      clientApiFetch<PaginatedResponse<Listing>>(`/listings?${params.toString()}`)
        .then((payload) => {
          if (!active) return;

          const next: Suggestion[] = [];
          const seen = new Set<string>();
          payload.data.forEach((listing) => {
            const key = `${listing.product.id}:${listing.variant.id}`;
            if (seen.has(key)) return;
            seen.add(key);
            next.push({
              key,
              href: `/products/${listing.product.id}?variant_id=${listing.variant.id}`,
              title: listing.product.name,
              subtitle: listing.variant.name,
              priceLabel: listing.price_cents == null ? null : formatInrFromCents(listing.price_cents),
            });
          });

          setSuggestions(next);
          setSuggestionsOpen(true);
        })
        .catch(() => {
          if (!active) return;
          setSuggestions([]);
          setSuggestionsOpen(false);
        })
        .finally(() => {
          if (active) setSearching(false);
        });
    }, 200);

    return () => {
      active = false;
      window.clearTimeout(timer);
    };
  }, [query]);

  useEffect(() => {
    function onPointerDown(event: PointerEvent) {
      const target = event.target as Node | null;
      if (!target) return;
      if (!searchRef.current) return;
      if (searchRef.current.contains(target)) return;
      setSuggestionsOpen(false);
    }

    window.addEventListener("pointerdown", onPointerDown);
    return () => window.removeEventListener("pointerdown", onPointerDown);
  }, []);

  async function logout() {
    try {
      await fetch("/api/auth/logout", { method: "POST" });
    } finally {
      setSession({ data: { user: null, marketplace: null } });
      router.refresh();
    }
  }

  function submitSearch(value: string) {
    const trimmed = value.trim();
    setSuggestionsOpen(false);
    if (!trimmed) {
      router.push("/products");
      return;
    }
    router.push(`/products?q=${encodeURIComponent(trimmed)}`);
  }

  return (
    <header className="fixed inset-x-0 top-0 z-40 border-b border-stone-900/10 bg-white/70 backdrop-blur">
      <div className="mx-auto flex h-16 max-w-7xl items-center gap-4 px-4 md:px-6">
        <Link href="/" className="shrink-0 text-sm font-semibold tracking-tight text-stone-900">
          Marketplace
        </Link>

        <div ref={searchRef} className="relative hidden flex-1 md:block">
          <form
            onSubmit={(event) => {
              event.preventDefault();
              submitSearch(query);
            }}
            className="relative"
          >
            <input
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              onFocus={() => {
                if (suggestions.length > 0) setSuggestionsOpen(true);
              }}
              placeholder="Search products"
              className="w-full rounded-2xl border border-stone-200 bg-white px-4 py-3 pr-10 text-sm outline-none ring-0 transition focus:border-stone-900"
            />
            <button
              type="submit"
              className="absolute right-3 top-1/2 -translate-y-1/2 rounded-full p-2 text-stone-600 hover:text-stone-900"
              aria-label="Search"
            >
              <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M21 21l-4.3-4.3" />
                <circle cx="11" cy="11" r="7" />
              </svg>
            </button>
          </form>

          <div
            className={cn(
              "absolute left-0 right-0 top-[3.2rem] overflow-hidden rounded-2xl border border-stone-200 bg-white shadow-lg",
              suggestionsOpen ? "block" : "hidden",
            )}
          >
            <div className="max-h-80 overflow-auto">
              {searching ? (
                <div className="px-4 py-3 text-xs font-medium text-stone-500">Searching…</div>
              ) : null}
              {suggestions.map((suggestion) => (
                <Link
                  key={suggestion.key}
                  href={suggestion.href}
                  onClick={() => setSuggestionsOpen(false)}
                  className="flex items-center justify-between gap-4 px-4 py-3 text-sm hover:bg-stone-50"
                >
                  <span>
                    <span className="block font-medium text-stone-900">{suggestion.title}</span>
                    <span className="block text-xs text-stone-500">{suggestion.subtitle}</span>
                  </span>
                  {suggestion.priceLabel ? (
                    <span className="shrink-0 text-xs font-semibold text-stone-900">{suggestion.priceLabel}</span>
                  ) : null}
                </Link>
              ))}
              {!searching && suggestions.length === 0 ? (
                <div className="px-4 py-3 text-xs font-medium text-stone-500">No matches yet.</div>
              ) : null}
            </div>
          </div>
        </div>

        <div className="ml-auto flex items-center gap-3">
          <Link
            href="/products"
            className="rounded-full border border-stone-200 bg-white px-4 py-2 text-sm font-medium text-stone-700 hover:border-stone-300 hover:text-stone-900 md:hidden"
          >
            Browse
          </Link>

          <Link
            href="/cart"
            className="relative inline-flex h-10 w-10 items-center justify-center rounded-full border border-stone-200 bg-white text-stone-700 hover:border-stone-300 hover:text-stone-900"
            aria-label="Cart"
          >
            <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M6 6h15l-1.5 9h-12z" />
              <path d="M6 6l-2-3H1" />
              <circle cx="9" cy="20" r="1" />
              <circle cx="18" cy="20" r="1" />
            </svg>
            <span className="absolute -right-1 -top-1 rounded-full bg-stone-900 px-2 py-0.5 text-[10px] font-semibold text-stone-50">
              {cartCountLabel(cart?.item_count ?? 0)}
            </span>
          </Link>

          {session?.data.user ? (
            <button
              type="button"
              onClick={logout}
              className="hidden rounded-full border border-stone-200 bg-white px-4 py-2 text-sm font-medium text-stone-700 hover:border-stone-300 hover:text-stone-900 md:inline-flex"
            >
              Sign out
            </button>
          ) : (
            <Link
              href={`/login?return_to=${returnTo}`}
              className="hidden rounded-full bg-stone-900 px-4 py-2 text-sm font-semibold text-stone-50 hover:bg-stone-800 md:inline-flex"
            >
              Sign in
            </Link>
          )}
        </div>
      </div>
    </header>
  );
}

