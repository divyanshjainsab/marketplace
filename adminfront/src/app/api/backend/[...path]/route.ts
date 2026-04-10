import { cookies } from "next/headers";
import { NextRequest, NextResponse } from "next/server";
import { ACCESS_COOKIE, REFRESH_COOKIE } from "@/lib/auth-cookies";

const TENANT_COOKIE = "af_tenant";

const HOP_BY_HOP_HEADERS = new Set([
  "connection",
  "content-length",
  "keep-alive",
  "proxy-authenticate",
  "proxy-authorization",
  "te",
  "trailer",
  "transfer-encoding",
  "upgrade",
]);

function backendBaseUrl() {
  return process.env.BACKEND_INTERNAL_URL ?? "http://backend:3000";
}

function tenantHeaderValue() {
  return cookies().get(TENANT_COOKIE)?.value ?? process.env.NEXT_PUBLIC_DEFAULT_TENANT ?? "";
}

async function requestBody(req: NextRequest) {
  if (req.method === "GET" || req.method === "HEAD") return undefined;

  const bytes = new Uint8Array(await req.arrayBuffer());
  return bytes.byteLength > 0 ? bytes : undefined;
}

async function backendFetch(path: string, req: NextRequest, body?: Uint8Array, cookieOverride?: string) {
  const url = new URL(path, backendBaseUrl());
  url.search = req.nextUrl.search;

  const headers = new Headers();
  const contentType = req.headers.get("content-type");
  if (contentType) headers.set("Content-Type", contentType);
  headers.set("Accept", "application/json");

  const tenant = tenantHeaderValue();
  if (tenant) headers.set("X-Marketplace-Subdomain", tenant);
  const cookieHeader = cookieOverride ?? req.headers.get("cookie");
  if (cookieHeader) headers.set("Cookie", cookieHeader);

  return fetch(url, {
    method: req.method,
    headers,
    body: body as any,
    cache: "no-store",
  });
}

async function refreshSession(req: NextRequest) {
  const response = await fetch(`${backendBaseUrl()}/auth/session/refresh`, {
    method: "POST",
    headers: {
      Accept: "application/json",
      ...(req.headers.get("cookie") ? { Cookie: req.headers.get("cookie") as string } : {}),
    },
    cache: "no-store",
  });

  if (!response.ok) return null;

  return (await response.json()) as {
    access_token: string;
    refresh_token: string;
    exp: number;
    refresh_exp: number;
  };
}

function proxyResponseFrom(upstream: Response) {
  const headers = new Headers();
  upstream.headers.forEach((value, key) => {
    if (!HOP_BY_HOP_HEADERS.has(key.toLowerCase())) {
      headers.set(key, value);
    }
  });
  return headers;
}

async function handle(req: NextRequest, params: { path: string[] }) {
  const path = `/api/${params.path.join("/")}`;
  const body = await requestBody(req);

  let upstream = await backendFetch(path, req, body);
  let refreshedTokens: { access_token: string; refresh_token: string; exp: number; refresh_exp: number } | null = null;

  const refreshToken = cookies().get(REFRESH_COOKIE)?.value ?? null;
  if (upstream.status === 401 && refreshToken) {
    refreshedTokens = await refreshSession(req);
    if (refreshedTokens) {
      const updatedCookie = `${ACCESS_COOKIE}=${refreshedTokens.access_token}; ${REFRESH_COOKIE}=${refreshedTokens.refresh_token}`;
      upstream = await backendFetch(path, req, body, updatedCookie);
    }
  }

  const payload = await upstream.arrayBuffer();
  const response = new NextResponse(payload, {
    status: upstream.status,
    headers: proxyResponseFrom(upstream),
  });

  if (refreshedTokens) {
    response.cookies.set(ACCESS_COOKIE, refreshedTokens.access_token, {
      httpOnly: true,
      sameSite: "strict",
      secure: process.env.NODE_ENV === "production",
      path: "/",
      maxAge: Math.max(refreshedTokens.exp - Math.floor(Date.now() / 1000), 60),
    });

    response.cookies.set(REFRESH_COOKIE, refreshedTokens.refresh_token, {
      httpOnly: true,
      sameSite: "strict",
      secure: process.env.NODE_ENV === "production",
      path: "/",
      maxAge: Math.max(refreshedTokens.refresh_exp - Math.floor(Date.now() / 1000), 300),
    });
  } else if (upstream.status === 401) {
    response.cookies.set(ACCESS_COOKIE, "", {
      httpOnly: true,
      sameSite: "strict",
      secure: process.env.NODE_ENV === "production",
      path: "/",
      maxAge: 0,
    });
    response.cookies.set(REFRESH_COOKIE, "", {
      httpOnly: true,
      sameSite: "strict",
      secure: process.env.NODE_ENV === "production",
      path: "/",
      maxAge: 0,
    });
  }

  return response;
}

export async function GET(req: NextRequest, { params }: { params: { path: string[] } }) {
  return handle(req, params);
}

export async function POST(req: NextRequest, { params }: { params: { path: string[] } }) {
  return handle(req, params);
}

export async function PATCH(req: NextRequest, { params }: { params: { path: string[] } }) {
  return handle(req, params);
}

export async function PUT(req: NextRequest, { params }: { params: { path: string[] } }) {
  return handle(req, params);
}

export async function DELETE(req: NextRequest, { params }: { params: { path: string[] } }) {
  return handle(req, params);
}
