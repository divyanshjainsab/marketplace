import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { requiredEnv } from "@/lib/env";

const ACCESS_COOKIE = "mp_access";
const REFRESH_COOKIE = "mp_refresh";

function sessionCookieOptions(overrides: { expires?: Date; maxAge?: number } = {}) {
  return {
    httpOnly: true,
    sameSite: "lax" as const,
    secure: process.env.NODE_ENV === "production",
    path: "/",
    domain: process.env.BACKEND_SESSION_COOKIE_DOMAIN || undefined,
    ...overrides,
  };
}

export async function POST() {
  const accessToken = cookies().get(ACCESS_COOKIE)?.value ?? null;
  const refreshToken = cookies().get(REFRESH_COOKIE)?.value ?? null;

  const cookieHeader = [
    accessToken ? `${ACCESS_COOKIE}=${accessToken}` : null,
    refreshToken ? `${REFRESH_COOKIE}=${refreshToken}` : null,
  ]
    .filter(Boolean)
    .join("; ");

  if (cookieHeader) {
    await fetch(`${requiredEnv("BACKEND_INTERNAL_URL")}/auth/session/logout`, {
      method: "POST",
      headers: {
        Accept: "application/json",
        "X-Frontend-Proxy": "1",
        Cookie: cookieHeader,
      },
      cache: "no-store",
    }).catch(() => null);
  }

  const response = NextResponse.json({ ok: true });
  response.cookies.set(ACCESS_COOKIE, "", sessionCookieOptions({ expires: new Date(0), maxAge: 0 }));
  response.cookies.set(REFRESH_COOKIE, "", sessionCookieOptions({ expires: new Date(0), maxAge: 0 }));
  return response;
}
