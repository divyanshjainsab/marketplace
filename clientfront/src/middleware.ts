import { NextResponse, type NextRequest } from "next/server";

const TENANT_COOKIE = "cf_tenant";

function extractTenant(hostname: string): string | null {
  const host = hostname.split(":")[0].toLowerCase();

  if (host === "localhost" || host === "127.0.0.1") return null;

  const parts = host.split(".");
  if (parts.length < 3) return null; // example.com

  const subdomain = parts[0];
  if (!subdomain || subdomain === "www") return null;
  return subdomain;
}

export function middleware(req: NextRequest) {
  const host = req.headers.get("host") ?? "";
  const tenant = extractTenant(host) ?? process.env.NEXT_PUBLIC_DEFAULT_TENANT ?? null;

  const res = NextResponse.next();
  if (tenant) {
    res.cookies.set(TENANT_COOKIE, tenant, {
      httpOnly: false,
      sameSite: "lax",
      secure: process.env.NODE_ENV === "production",
      path: "/",
    });
  }

  return res;
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico).*)"],
};
