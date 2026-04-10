import { cookies } from "next/headers";
import { NextRequest, NextResponse } from "next/server";

const ADMIN_JWT_COOKIE = "af_jwt";
const ADMIN_REFRESH_COOKIE = "af_refresh";
const TENANT_COOKIE = "af_tenant";
const ORG_COOKIE = "af_org_slug";

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

function ssoBaseUrl() {
  return process.env.SSO_INTERNAL_URL ?? "http://sso:3000";
}

function tenantHeaderValue() {
  return cookies().get(TENANT_COOKIE)?.value ?? process.env.NEXT_PUBLIC_DEFAULT_TENANT ?? "";
}

function orgHeaderValue() {
  return cookies().get(ORG_COOKIE)?.value ?? "";
}

async function requestBody(req: NextRequest) {
  if (req.method === "GET" || req.method === "HEAD") return undefined;

  const buffer = Buffer.from(await req.arrayBuffer());
  return buffer.byteLength > 0 ? buffer : undefined;
}

async function backendFetch(path: string, req: NextRequest, token: string | null, body?: Buffer) {
  const url = new URL(path, backendBaseUrl());
  url.search = req.nextUrl.search;

  const headers = new Headers();
  const contentType = req.headers.get("content-type");
  if (contentType) headers.set("Content-Type", contentType);
  headers.set("Accept", "application/json");

  const tenant = tenantHeaderValue();
  if (tenant) headers.set("X-Marketplace-Subdomain", tenant);
  const orgSlug = orgHeaderValue();
  if (orgSlug) headers.set("X-Organization-Slug", orgSlug);
  if (token) headers.set("Authorization", `Bearer ${token}`);

  return fetch(url, {
    method: req.method,
    headers,
    body,
    cache: "no-store",
  });
}

async function refreshAccessToken(refreshToken: string) {
  const response = await fetch(`${ssoBaseUrl()}/refresh_token`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
    },
    body: JSON.stringify({ refresh_token: refreshToken }),
    cache: "no-store",
  });

  if (!response.ok) return null;

  return (await response.json()) as {
    token: string;
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

  let accessToken = cookies().get(ADMIN_JWT_COOKIE)?.value ?? null;
  let refreshToken = cookies().get(ADMIN_REFRESH_COOKIE)?.value ?? null;
  let upstream = await backendFetch(path, req, accessToken, body);
  let refreshedTokens: { token: string; refresh_token: string; exp: number; refresh_exp: number } | null = null;

  if (upstream.status === 401 && refreshToken) {
    refreshedTokens = await refreshAccessToken(refreshToken);
    if (refreshedTokens) {
      accessToken = refreshedTokens.token;
      refreshToken = refreshedTokens.refresh_token;
      upstream = await backendFetch(path, req, accessToken, body);
    }
  }

  const payload = await upstream.arrayBuffer();
  const response = new NextResponse(payload, {
    status: upstream.status,
    headers: proxyResponseFrom(upstream),
  });

  if (refreshedTokens) {
    response.cookies.set(ADMIN_JWT_COOKIE, refreshedTokens.token, {
      httpOnly: true,
      sameSite: "lax",
      secure: process.env.NODE_ENV === "production",
      path: "/",
      maxAge: Math.max(refreshedTokens.exp - Math.floor(Date.now() / 1000), 60),
    });

    response.cookies.set(ADMIN_REFRESH_COOKIE, refreshedTokens.refresh_token, {
      httpOnly: true,
      sameSite: "lax",
      secure: process.env.NODE_ENV === "production",
      path: "/",
      maxAge: Math.max(refreshedTokens.refresh_exp - Math.floor(Date.now() / 1000), 300),
    });
  } else if (upstream.status === 401) {
    response.cookies.set(ADMIN_JWT_COOKIE, "", {
      httpOnly: true,
      sameSite: "lax",
      secure: process.env.NODE_ENV === "production",
      path: "/",
      maxAge: 0,
    });
    response.cookies.set(ADMIN_REFRESH_COOKIE, "", {
      httpOnly: true,
      sameSite: "lax",
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
