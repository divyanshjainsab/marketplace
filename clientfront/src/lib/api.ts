import "server-only";
import { getJwt, getRefreshToken, ACCESS_COOKIE, REFRESH_COOKIE } from "@/lib/auth";
import { requiredEnv } from "@/lib/env";
import { headers as nextHeaders } from "next/headers";

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

  const headers = new Headers(init?.headers);
  headers.set("Accept", "application/json");
  headers.set("X-Frontend-Proxy", "1");

  const cookie = [
    jwt ? `${ACCESS_COOKIE}=${jwt}` : null,
    refreshToken ? `${REFRESH_COOKIE}=${refreshToken}` : null,
  ]
    .filter(Boolean)
    .join("; ");
  if (cookie) headers.set("Cookie", cookie);

  // Ensure the backend can resolve tenant purely from request host/port even when
  // this fetch runs server-side (Node) against BACKEND_INTERNAL_URL.
  const incoming = nextHeaders();
  const forwardedHost = incoming.get("x-forwarded-host") ?? incoming.get("host");
  if (forwardedHost) {
    headers.set("X-Forwarded-Host", forwardedHost);
    const forwardedPort = forwardedHost.split(":")[1];
    if (forwardedPort) headers.set("X-Forwarded-Port", forwardedPort);
  }
  const forwardedProto = incoming.get("x-forwarded-proto");
  if (forwardedProto) headers.set("X-Forwarded-Proto", forwardedProto);

  const res = await fetch(`${backendBaseUrl()}${path}`, {
    ...init,
    headers,
    cache: init?.cache ?? (init?.next ? undefined : "no-store"),
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
