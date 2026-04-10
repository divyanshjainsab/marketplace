import { NextResponse, type NextRequest } from "next/server";
import { ACCESS_COOKIE } from "./lib/auth-cookies";

const TENANT_COOKIE = "af_tenant";

function extractTenant(hostname: string): string | null {
  const host = hostname.split(":")[0].toLowerCase();

  if (host === "localhost" || host === "127.0.0.1") return null;

  const parts = host.split(".");
  if (parts.length < 3) return null;

  const subdomain = parts[0];
  if (!subdomain || subdomain === "www") return null;
  return subdomain;
}

export function middleware(req: NextRequest) {
  const { pathname, search } = req.nextUrl;
  const host = req.headers.get("host") ?? "";
  const tenant = extractTenant(host) ?? process.env.NEXT_PUBLIC_DEFAULT_TENANT ?? null;

  const applyTenantCookie = (res: NextResponse) => {
    if (tenant) {
      res.cookies.set(TENANT_COOKIE, tenant, {
        httpOnly: false,
        sameSite: "lax",
        secure: process.env.NODE_ENV === "production",
        path: "/",
      });
    }
    return res;
  };

  const isNextAsset = pathname.startsWith("/_next");
  const isApiRoute = pathname.startsWith("/api");
  if (isNextAsset || isApiRoute) return applyTenantCookie(NextResponse.next());

  const isAuthRoute = pathname === "/login" || pathname === "/callback" || pathname === "/not-authorized";
  const jwt = req.cookies.get(ACCESS_COOKIE)?.value ?? null;

  if (pathname === "/") {
    const url = req.nextUrl.clone();
    url.pathname = jwt ? "/dashboard" : "/login";
    url.search = "";
    return applyTenantCookie(NextResponse.redirect(url));
  }

  if (pathname === "/login") {
    if (!jwt) return applyTenantCookie(NextResponse.next());
    const url = req.nextUrl.clone();
    url.pathname = "/dashboard";
    url.search = "";
    return applyTenantCookie(NextResponse.redirect(url));
  }

  if (!jwt && !isAuthRoute) {
    const url = req.nextUrl.clone();
    const returnTo = `${pathname}${search}`;
    url.pathname = "/login";
    url.searchParams.set("return_to", returnTo);
    return applyTenantCookie(NextResponse.redirect(url));
  }

  return applyTenantCookie(NextResponse.next());
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico).*)"],
};
