import { NextResponse } from "next/server";
import { cookies } from "next/headers";

const ACCESS_COOKIE = "mp_access";
const REFRESH_COOKIE = "mp_refresh";

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
    await fetch(`${process.env.BACKEND_INTERNAL_URL ?? "http://backend:3000"}/auth/session/logout`, {
      method: "POST",
      headers: {
        Accept: "application/json",
        Cookie: cookieHeader,
      },
      cache: "no-store",
    }).catch(() => null);
  }

  cookies().set(ACCESS_COOKIE, "", {
    httpOnly: true,
    sameSite: "strict",
    secure: process.env.NODE_ENV === "production",
    path: "/",
    maxAge: 0,
  });

  cookies().set(REFRESH_COOKIE, "", {
    httpOnly: true,
    sameSite: "strict",
    secure: process.env.NODE_ENV === "production",
    path: "/",
    maxAge: 0,
  });

  return NextResponse.json({ ok: true });
}
