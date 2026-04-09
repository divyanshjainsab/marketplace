import "server-only";
import { getJwt } from "@/lib/auth";
import { getTenant } from "@/lib/tenant";

export class ApiError extends Error {
  status: number;
  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

function backendBaseUrl() {
  return process.env.BACKEND_INTERNAL_URL ?? "http://backend:3000";
}

export async function apiFetch<T>(
  path: string,
  init?: RequestInit,
): Promise<T> {
  const jwt = getJwt();
  const tenant = getTenant();

  const headers = new Headers(init?.headers);
  headers.set("Accept", "application/json");

  if (jwt) headers.set("Authorization", `Bearer ${jwt}`);
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
