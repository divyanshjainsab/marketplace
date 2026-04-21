"use client";

import { useEffect, useState } from "react";
import { useSearchParams } from "next/navigation";

function sanitizeReturnTo(raw: string | null): string {
  const value = (raw ?? "").trim();
  if (!value) return "/";
  if (!value.startsWith("/")) return "/";
  if (value.startsWith("//")) return "/";
  return value;
}

export default function LoginPage() {
  const searchParams = useSearchParams();
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    try {
      const apiBase = (process.env.NEXT_PUBLIC_API_URL || "").replace(/\/+$/, "");
      if (!apiBase) throw new Error("missing NEXT_PUBLIC_API_URL");
      const returnTo = sanitizeReturnTo(searchParams.get("return_to"));

      const originHost = window.location.hostname;
      const originPort = window.location.port || "3002";
      const originScheme = window.location.protocol.replace(":", "");

      const url = new URL(`${apiBase}/auth/oidc/start/clientfront`);
      url.searchParams.set("return_to", returnTo);
      url.searchParams.set("origin_host", originHost);
      url.searchParams.set("origin_port", originPort);
      url.searchParams.set("origin_scheme", originScheme);

      window.location.assign(url.toString());
    } catch {
      setError("Unable to start sign-in. Please refresh and try again.");
    }
  }, [searchParams]);

  return (
    <main className="mx-auto flex min-h-[60vh] max-w-md flex-col items-center justify-center px-6 py-16">
      <div className="w-full rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <h1 className="text-balance text-lg font-semibold text-slate-900">Signing you in</h1>
        <p className="mt-2 text-sm text-slate-600">Redirecting to SSO.</p>
        {error ? (
          <p className="mt-4 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800">
            {error}
          </p>
        ) : null}
      </div>
    </main>
  );
}
