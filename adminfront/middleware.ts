import { NextResponse, type NextRequest } from "next/server";

const TENANT_COOKIE = "af_tenant";
const ORG_COOKIE = "af_org_slug";

function extractTenant(hostname: string): string | null {
  const host = hostname.split(":")[0].toLowerCase();

  if (host === "localhost" || host === "127.0.0.1") return null;

  const parts = host.split(".");
  if (parts.length < 3) return null;

  const subdomain = parts[0];
  if (!subdomain || subdomain === "www") return null;
  return subdomain;
}

function extractOrgSlug(pathname: string): string | null {
  const segment = pathname.split("/")[1]?.toLowerCase() ?? "";
  if (!segment) return null;

  if (segment === "api" || segment === "callback" || segment === "not-authorized") return null;
  if (!/^[a-z0-9][a-z0-9-]*$/.test(segment)) return null;
  return segment;
}

export function middleware(req: NextRequest) {
  const res = NextResponse.next();

  const host = req.headers.get("host") ?? "";
  const tenant = extractTenant(host) ?? process.env.NEXT_PUBLIC_DEFAULT_TENANT ?? null;
  const orgSlug = extractOrgSlug(req.nextUrl.pathname);

  if (tenant) {
    res.cookies.set(TENANT_COOKIE, tenant, {
      httpOnly: false,
      sameSite: "lax",
      secure: process.env.NODE_ENV === "production",
      path: "/",
    });
  }

  if (orgSlug) {
    res.cookies.set(ORG_COOKIE, orgSlug, {
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
