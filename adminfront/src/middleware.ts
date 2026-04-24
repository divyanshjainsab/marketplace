import { NextResponse, type NextRequest } from "next/server";
import { ACCESS_COOKIE, REFRESH_COOKIE } from "./lib/auth-cookies";

export function middleware(req: NextRequest) {
  const { pathname, search } = req.nextUrl;

  const isNextAsset = pathname.startsWith("/_next");
  const isApiRoute = pathname.startsWith("/api");
  if (isNextAsset || isApiRoute) return NextResponse.next();

  const isAuthRoute = pathname === "/login" || pathname === "/callback" || pathname === "/not-authorized";
  const hasSession =
    (req.cookies.get(ACCESS_COOKIE)?.value ?? "").length > 0 ||
    (req.cookies.get(REFRESH_COOKIE)?.value ?? "").length > 0;

  if (pathname === "/") {
    const url = req.nextUrl.clone();
    url.pathname = hasSession ? "/dashboard" : "/login";
    url.search = "";
    return NextResponse.redirect(url);
  }

  if (pathname === "/login") {
    if (!hasSession) return NextResponse.next();
    const url = req.nextUrl.clone();
    url.pathname = "/dashboard";
    url.search = "";
    return NextResponse.redirect(url);
  }

  if (!hasSession && !isAuthRoute) {
    const url = req.nextUrl.clone();
    const returnTo = `${pathname}${search}`;
    url.pathname = "/login";
    url.search = "";
    url.searchParams.set("return_to", returnTo);
    return NextResponse.redirect(url);
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico).*)"],
};
