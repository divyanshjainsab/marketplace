import { redirect } from "next/navigation";

type LoginPageProps = {
  params: { org: string };
  searchParams?: Record<string, string | string[] | undefined>;
};

function sanitizeReturnTo(raw: unknown): string | null {
  if (typeof raw !== "string") return null;
  const value = raw.trim();
  if (!value) return null;
  if (!value.startsWith("/")) return null;
  if (value.startsWith("//")) return null;
  return value;
}

export default function LoginPage({ params, searchParams }: LoginPageProps) {
  const ssoBase = (process.env.NEXT_PUBLIC_SSO_URL ?? "http://localhost:3002").replace(/\/+$/, "");
  const apiBase = (process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:3001").replace(/\/+$/, "");

  const orgSlug = params.org;
  const returnTo = sanitizeReturnTo(searchParams?.return_to) ?? `/${orgSlug}/dashboard`;
  const redirectUri = `${apiBase}/auth/sso/callback?app=admin`;

  redirect(
    `${ssoBase}/login?redirect_uri=${encodeURIComponent(redirectUri)}&return_to=${encodeURIComponent(returnTo)}&org_slug=${encodeURIComponent(orgSlug)}`,
  );
}

