"use client";

import React, { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from "react";
import { clientApiFetch } from "@/lib/client-api";
import type { Cart } from "@/lib/types";

type CartContextValue = {
  cart: Cart | null;
  cartId: string | null;
  loading: boolean;
  refresh: () => Promise<Cart | null>;
  addItem: (variantId: number, quantity?: number) => Promise<Cart>;
  setQuantity: (variantId: number, quantity: number) => Promise<Cart>;
  removeItem: (variantId: number) => Promise<Cart>;
};

const CartContext = createContext<CartContextValue | null>(null);

const CART_ID_STORAGE_KEY = "mp_cart_id";

function generateCartId(): string {
  if (typeof crypto !== "undefined" && typeof crypto.randomUUID === "function") {
    return crypto.randomUUID();
  }
  return `${Date.now()}-${Math.random().toString(16).slice(2)}-${Math.random().toString(16).slice(2)}`;
}

function readStoredCartId(): string | null {
  try {
    return window.localStorage.getItem(CART_ID_STORAGE_KEY);
  } catch {
    return null;
  }
}

function storeCartId(value: string) {
  try {
    window.localStorage.setItem(CART_ID_STORAGE_KEY, value);
  } catch {
    // ignore
  }
}

export function CartProvider({ children }: React.PropsWithChildren) {
  const [cartId, setCartId] = useState<string | null>(null);
  const [cart, setCart] = useState<Cart | null>(null);
  const [loading, setLoading] = useState(true);
  const initializing = useRef(true);

  const syncCart = useCallback((next: Cart) => {
    setCart(next);
    if (next.session_id && next.session_id !== cartId) {
      storeCartId(next.session_id);
      setCartId(next.session_id);
    }
  }, [cartId]);

  const refresh = useCallback(async () => {
    if (!cartId) return null;
    setLoading(true);
    try {
      const payload = await clientApiFetch<{ data: Cart }>(`/cart?session_id=${encodeURIComponent(cartId)}`);
      syncCart(payload.data);
      return payload.data;
    } finally {
      setLoading(false);
    }
  }, [cartId, syncCart]);

  const addItem = useCallback(async (variantId: number, quantity = 1) => {
    if (!cartId) throw new Error("Cart not initialized");
    const payload = await clientApiFetch<{ data: Cart }>(`/cart/items?session_id=${encodeURIComponent(cartId)}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ variant_id: variantId, quantity }),
    });
    syncCart(payload.data);
    return payload.data;
  }, [cartId, syncCart]);

  const setQuantity = useCallback(async (variantId: number, quantity: number) => {
    if (!cartId) throw new Error("Cart not initialized");
    const payload = await clientApiFetch<{ data: Cart }>(`/cart/items/${variantId}?session_id=${encodeURIComponent(cartId)}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ quantity }),
    });
    syncCart(payload.data);
    return payload.data;
  }, [cartId, syncCart]);

  const removeItem = useCallback(async (variantId: number) => {
    if (!cartId) throw new Error("Cart not initialized");
    const payload = await clientApiFetch<{ data: Cart }>(`/cart/items/${variantId}?session_id=${encodeURIComponent(cartId)}`, {
      method: "DELETE",
    });
    syncCart(payload.data);
    return payload.data;
  }, [cartId, syncCart]);

  useEffect(() => {
    if (!initializing.current) return;
    initializing.current = false;

    const stored = readStoredCartId();
    const id = stored?.trim() ? stored.trim() : generateCartId();
    storeCartId(id);
    setCartId(id);
  }, []);

  useEffect(() => {
    if (!cartId) return;
    refresh().catch(() => {
      // If the cart cannot be fetched, keep the cart id but surface as empty.
      setCart({
        id: -1,
        marketplace_id: -1,
        user_id: null,
        session_id: cartId,
        item_count: 0,
        subtotal_cents: 0,
        items: [],
      });
    });
  }, [cartId, refresh]);

  const value = useMemo<CartContextValue>(() => {
    return {
      cart,
      cartId,
      loading,
      refresh,
      addItem,
      setQuantity,
      removeItem,
    };
  }, [addItem, cart, cartId, loading, refresh, removeItem, setQuantity]);

  return <CartContext.Provider value={value}>{children}</CartContext.Provider>;
}

export function useCart() {
  const context = useContext(CartContext);
  if (!context) {
    throw new Error("useCart must be used within CartProvider");
  }
  return context;
}

