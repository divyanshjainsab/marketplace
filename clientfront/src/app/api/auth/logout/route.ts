import { NextRequest, NextResponse } from "next/server";
import { ACCESS_COOKIE, REFRESH_COOKIE } from "@/lib/auth";
import { requiredEnv } from "@/lib/env";

function backendBaseUrl() {
  return requiredEnv("BACKEND_INTERNAL_URL");
}

function sessionCookieDomain() {
  return process.env.BACKEND_SESSION_COOKIE_DOMAIN || undefined;
}

function sessionCookieOptions(overrides: { expires?: Date; maxAge?: number } = {}) {
  return {
    httpOnly: true,
    sameSite: "lax" as const,
    secure: process.env.NODE_ENV === "production",
    path: "/",
    domain: sessionCookieDomain(),
    ...overrides,
  };
}

export async function POST(req: NextRequest) {
  await fetch(`${backendBaseUrl()}/auth/session/logout`, {
    method: "POST",
    headers: {
      Accept: "application/json",
      "X-Frontend-Proxy": "1",
      ...(req.headers.get("cookie") ? { Cookie: req.headers.get("cookie") as string } : {}),
    },
    cache: "no-store",
  }).catch(() => null);

  const response = NextResponse.json({ ok: true });
  response.cookies.set(ACCESS_COOKIE, "", { ...sessionCookieOptions({ expires: new Date(0), maxAge: 0 }) });
  response.cookies.set(REFRESH_COOKIE, "", { ...sessionCookieOptions({ expires: new Date(0), maxAge: 0 }) });
  return response;
}

