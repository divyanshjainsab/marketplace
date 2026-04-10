"use client";

import { useEffect, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";

function sanitizeReturnTo(raw: string | null): string {
  const value = (raw ?? "").trim();
  if (!value) return "/";
  if (!value.startsWith("/")) return "/";
  if (value.startsWith("//")) return "/";
  return value;
}

export default function CallbackPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const token = searchParams.get("token");
    const refreshToken = searchParams.get("refresh_token");
    const exp = searchParams.get("exp");
    const refreshExp = searchParams.get("refresh_exp");
    const returnTo = sanitizeReturnTo(searchParams.get("return_to") ?? searchParams.get("redirect"));

    if (!token || !refreshToken) {
      router.replace(`/login?return_to=${encodeURIComponent(returnTo)}`);
      router.refresh();
      return;
    }

    (async () => {
      const response = await fetch("/api/auth/session", {
        method: "POST",
        headers: { "Content-Type": "application/json", Accept: "application/json" },
        body: JSON.stringify({
          token,
          refresh_token: refreshToken,
          exp: exp ? Number(exp) : undefined,
          refresh_exp: refreshExp ? Number(refreshExp) : undefined,
        }),
      });

      if (!response.ok) {
        setError("Unable to complete sign-in. Please try again.");
        return;
      }

      router.replace(returnTo);
      router.refresh();
    })().catch(() => {
      setError("Unable to complete sign-in. Please try again.");
    });
  }, [router, searchParams]);

  return (
    <main className="mx-auto flex min-h-[60vh] max-w-md flex-col items-center justify-center px-6 py-16">
      <div className="w-full rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <h1 className="text-balance text-lg font-semibold text-slate-900">Signing you in</h1>
        <p className="mt-2 text-sm text-slate-600">One moment while we finish your session.</p>
        {error ? (
          <p className="mt-4 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800">
            {error}
          </p>
        ) : (
          <div className="mt-6 h-1.5 w-full overflow-hidden rounded-full bg-slate-100">
            <div className="h-full w-1/2 animate-pulse rounded-full bg-slate-900" />
          </div>
        )}
      </div>
    </main>
  );
}

