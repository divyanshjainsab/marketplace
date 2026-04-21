import "server-only";
import { getJwt, getRefreshToken, ACCESS_COOKIE, REFRESH_COOKIE } from "@/lib/auth";
import { getTenant } from "@/lib/tenant";
import { requiredEnv } from "@/lib/env";

export class ApiError extends Error {
  status: number;
  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

function backendBaseUrl() {
  return requiredEnv("BACKEND_INTERNAL_URL");
}

export async function apiFetch<T>(
  path: string,
  init?: RequestInit,
): Promise<T> {
  const jwt = getJwt();
  const refreshToken = getRefreshToken();
  const tenant = getTenant();

  const headers = new Headers(init?.headers);
  headers.set("Accept", "application/json");

  const cookie = [
    jwt ? `${ACCESS_COOKIE}=${jwt}` : null,
    refreshToken ? `${REFRESH_COOKIE}=${refreshToken}` : null,
  ]
    .filter(Boolean)
    .join("; ");
  if (cookie) headers.set("Cookie", cookie);
  if (tenant.subdomain) headers.set("X-Marketplace-Subdomain", tenant.subdomain);

  const res = await fetch(`${backendBaseUrl()}${path}`, {
    ...init,
    headers,
    cache: "no-store",
  });

  if (!res.ok) {
    let message = `API error (${res.status})`;
    try {
      const body = await res.json();
      message = body?.error ? String(body.error) : message;
    } catch {
      // ignore
    }
    throw new ApiError(res.status, message);
  }

  return (await res.json()) as T;
}
