"use client";

import { useEffect, useMemo, useState } from "react";
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

  const returnTo = useMemo(() => sanitizeReturnTo(searchParams.get("return_to")), [searchParams]);
  const oidcError = searchParams.get("error");
  const oidcErrorDescription = searchParams.get("error_description");

  useEffect(() => {
    if (oidcError) return;

    try {
      const apiBase = (process.env.NEXT_PUBLIC_API_URL || "").replace(/\/+$/, "");
      if (!apiBase) throw new Error("missing NEXT_PUBLIC_API_URL");

      const originHost = window.location.hostname;
      const originPort = window.location.port || "3000";
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
  }, [oidcError, returnTo]);

  const message = oidcError
    ? `Sign-in failed: ${oidcErrorDescription || oidcError}.`
    : error;

  return (
    <main className="mx-auto flex min-h-[60vh] max-w-md flex-col items-center justify-center px-6 py-16">
      <div className="w-full rounded-2xl border border-stone-200 bg-white p-6 shadow-sm">
        <h1 className="text-balance text-lg font-semibold text-stone-900">
          {oidcError ? "Sign-in error" : "Signing you in"}
        </h1>
        <p className="mt-2 text-sm text-stone-600">
          {oidcError ? "Please try again." : "Redirecting to SSO."}
        </p>
        {message ? (
          <p className="mt-4 rounded-xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-800">
            {message}
          </p>
        ) : null}
      </div>
    </main>
  );
}

