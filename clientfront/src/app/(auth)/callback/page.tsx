"use client";

import { useEffect, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";

export default function AuthCallbackPage() {
  const router = useRouter();
  const params = useSearchParams();
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const token = params.get("token");
    const refreshToken = params.get("refresh_token");
    const exp = params.get("exp");
    const refreshExp = params.get("refresh_exp");

    if (!token || !refreshToken) {
      setError("Missing token");
      return;
    }

    (async () => {
      const res = await fetch("/api/auth/session", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          token,
          refresh_token: refreshToken,
          exp: exp ? Number(exp) : undefined,
          refresh_exp: refreshExp ? Number(refreshExp) : undefined,
        }),
      });

      if (!res.ok) {
        const body = (await res.json().catch(() => null)) as any;
        setError(body?.error ?? "Failed to store session");
        return;
      }

      router.replace("/dashboard");
    })().catch((e) => setError(e?.message ?? "Failed to store session"));
  }, [params, router]);

  return (
    <main style={{ padding: 24 }}>
      <h1>Signing you in…</h1>
      {error ? <p style={{ color: "crimson" }}>{error}</p> : null}
    </main>
  );
}
