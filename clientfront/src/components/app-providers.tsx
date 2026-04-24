"use client";

import { CartProvider } from "@/components/cart/cart-provider";
import { StorefrontNavbar } from "@/components/shell/storefront-navbar";
import { ToastProvider } from "@/components/toast-provider";

export function AppProviders({ children }: { children: React.ReactNode }) {
  return (
    <ToastProvider>
      <CartProvider>
        <div className="min-h-screen bg-[linear-gradient(180deg,_#f8f3ea_0%,_#f0e5d4_100%)] text-stone-900">
          <StorefrontNavbar />
          <div className="pt-20">{children}</div>
        </div>
      </CartProvider>
    </ToastProvider>
  );
}

