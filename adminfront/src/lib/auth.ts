import "server-only";
import { cookies } from "next/headers";
import { ACCESS_COOKIE, REFRESH_COOKIE } from "@/lib/auth-cookies";

export function getJwt(): string | null {
  return cookies().get(ACCESS_COOKIE)?.value ?? null;
}

export function getRefreshToken(): string | null {
  return cookies().get(REFRESH_COOKIE)?.value ?? null;
}
