import "server-only";
import { cookies, headers } from "next/headers";

export const TENANT_COOKIE = "cf_tenant";

export type Tenant = {
  subdomain: string | null;
};

function extractTenantFromHost(host: string): string | null {
  const hostname = host.split(":")[0].toLowerCase();

  if (hostname === "localhost" || hostname === "127.0.0.1") return null;

  const parts = hostname.split(".");
  if (parts.length < 3) return null;

  const subdomain = parts[0];
  if (!subdomain || subdomain === "www") return null;
  return subdomain;
}

export function getTenant(): Tenant {
  const host = headers().get("host") ?? "";
  const fromHost = extractTenantFromHost(host);
  const fromCookie = cookies().get(TENANT_COOKIE)?.value ?? null;

  // Allow overriding tenant in local dev via cookie.
  return { subdomain: fromHost ?? fromCookie };
}
