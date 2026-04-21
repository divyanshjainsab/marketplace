import { NextResponse, type NextRequest } from "next/server";
import { requiredEnv } from "./lib/env";

const ACCESS_COOKIE = "mp_access";
const REFRESH_COOKIE = "mp_refresh";
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
  const { pathname, search } = req.nextUrl;
  const host = req.headers.get("host") ?? "";
  const hostname = host.split(":")[0].toLowerCase();
  const isLocalhost = hostname === "localhost" || hostname === "127.0.0.1";
  let tenant = extractTenant(host);
  if (!tenant && !isLocalhost) tenant = requiredEnv("NEXT_PUBLIC_DEFAULT_TENANT");

  const applyTenantCookie = (res: NextResponse) => {
    if (tenant) {
      res.cookies.set(TENANT_COOKIE, tenant, {
        httpOnly: false,
        sameSite: "lax",
        secure: process.env.NODE_ENV === "production",
        path: "/",
      });
    } else {
      res.cookies.set(TENANT_COOKIE, "", {
        httpOnly: false,
        sameSite: "lax",
        secure: process.env.NODE_ENV === "production",
        path: "/",
        maxAge: 0,
      });
    }

    return res;
  };

  const hasSession =
    (req.cookies.get(ACCESS_COOKIE)?.value ?? "").length > 0 ||
    (req.cookies.get(REFRESH_COOKIE)?.value ?? "").length > 0;
  const isAuthRoute = pathname === "/login" || pathname === "/callback";
  const isProtectedRoute =
    pathname === "/dashboard" ||
    pathname === "/catalog" ||
    pathname.startsWith("/listings");

  if (pathname === "/login" && hasSession) {
    const url = req.nextUrl.clone();
    url.pathname = "/dashboard";
    url.search = "";
    return applyTenantCookie(NextResponse.redirect(url));
  }

  if (!hasSession && isProtectedRoute && !isAuthRoute) {
    const url = req.nextUrl.clone();
    url.pathname = "/login";
    url.search = "";
    url.searchParams.set("return_to", `${pathname}${search}`);
    return applyTenantCookie(NextResponse.redirect(url));
  }

  return applyTenantCookie(NextResponse.next());
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico).*)"],
};
