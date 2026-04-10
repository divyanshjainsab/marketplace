import { redirect } from "next/navigation";

type LoginPageProps = {
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

export default function LoginPage({ searchParams }: LoginPageProps) {
  const apiBase = (process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:3001").replace(/\/+$/, "");

  const returnTo = sanitizeReturnTo(searchParams?.return_to) ?? "/dashboard";

  const orgSlug =
    typeof searchParams?.org_slug === "string"
      ? searchParams.org_slug
      : process.env.NEXT_PUBLIC_DEFAULT_ORG_SLUG ?? "demo-org";

  redirect(
    `${apiBase}/auth/oidc/start/admin?return_to=${encodeURIComponent(returnTo)}&org_slug=${encodeURIComponent(orgSlug)}`,
  );
}
