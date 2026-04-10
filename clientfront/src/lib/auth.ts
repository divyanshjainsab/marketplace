import "server-only";
import { cookies } from "next/headers";

export const ACCESS_COOKIE = "mp_access";
export const REFRESH_COOKIE = "mp_refresh";

export function getJwt(): string | null {
  return cookies().get(ACCESS_COOKIE)?.value ?? null;
}

export function getRefreshToken(): string | null {
  return cookies().get(REFRESH_COOKIE)?.value ?? null;
}
