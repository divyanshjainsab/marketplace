import "server-only";
import { cookies } from "next/headers";

export const APP_JWT_COOKIE = "cf_jwt";
export const APP_REFRESH_COOKIE = "cf_refresh";

export function getJwt(): string | null {
  return cookies().get(APP_JWT_COOKIE)?.value ?? null;
}

export function getRefreshToken(): string | null {
  return cookies().get(APP_REFRESH_COOKIE)?.value ?? null;
}
