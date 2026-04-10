import "server-only";
import { cookies } from "next/headers";

export const ADMIN_JWT_COOKIE = "af_jwt";
export const ADMIN_REFRESH_COOKIE = "af_refresh";

export function getJwt(): string | null {
  return cookies().get(ADMIN_JWT_COOKIE)?.value ?? null;
}

export function getRefreshToken(): string | null {
  return cookies().get(ADMIN_REFRESH_COOKIE)?.value ?? null;
}

