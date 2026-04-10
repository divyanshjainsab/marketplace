import { NextResponse } from "next/server";
import { cookies } from "next/headers";

const COOKIE_NAME = "af_jwt";
const REFRESH_COOKIE_NAME = "af_refresh";

export async function POST() {
  const token = cookies().get(COOKIE_NAME)?.value;
  const refreshToken = cookies().get(REFRESH_COOKIE_NAME)?.value;

  if (token || refreshToken) {
    await fetch(`${process.env.SSO_INTERNAL_URL ?? "http://sso:3000"}/logout`, {
      method: "DELETE",
      headers: {
        "Content-Type": "application/json",
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      body: JSON.stringify({ refresh_token: refreshToken }),
      cache: "no-store",
    }).catch(() => null);
  }

  cookies().set(COOKIE_NAME, "", {
    httpOnly: true,
    sameSite: "lax",
    secure: process.env.NODE_ENV === "production",
    path: "/",
    maxAge: 0,
  });

  cookies().set(REFRESH_COOKIE_NAME, "", {
    httpOnly: true,
    sameSite: "lax",
    secure: process.env.NODE_ENV === "production",
    path: "/",
    maxAge: 0,
  });

  return NextResponse.json({ ok: true });
}

