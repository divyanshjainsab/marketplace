import { NextResponse } from "next/server";
import { cookies } from "next/headers";

const COOKIE_NAME = "cf_jwt";
const REFRESH_COOKIE_NAME = "cf_refresh";

export async function POST(req: Request) {
  const body = (await req.json().catch(() => null)) as { token?: string; refresh_token?: string; exp?: number; refresh_exp?: number } | null;
  const token = body?.token?.toString().trim();
  const refreshToken = body?.refresh_token?.toString().trim();

  if (!token || !refreshToken) {
    return NextResponse.json({ ok: false, error: "missing_token" }, { status: 400 });
  }

  const accessMaxAge = body?.exp ? Math.max(body.exp - Math.floor(Date.now() / 1000), 60) : undefined;
  const refreshMaxAge = body?.refresh_exp ? Math.max(body.refresh_exp - Math.floor(Date.now() / 1000), 300) : undefined;

  cookies().set(COOKIE_NAME, token, {
    httpOnly: true,
    sameSite: "lax",
    secure: process.env.NODE_ENV === "production",
    path: "/",
    maxAge: accessMaxAge,
  });

  cookies().set(REFRESH_COOKIE_NAME, refreshToken, {
    httpOnly: true,
    sameSite: "lax",
    secure: process.env.NODE_ENV === "production",
    path: "/",
    maxAge: refreshMaxAge,
  });

  return NextResponse.json({ ok: true });
}
