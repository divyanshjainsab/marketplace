import { redirect } from "next/navigation";

type LoginRedirectProps = {
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

export default function LegacyOrgLoginPage({ params, searchParams }: LoginRedirectProps) {
  const returnTo = sanitizeReturnTo(searchParams?.return_to) ?? "/dashboard";
  redirect(`/login?org_slug=${encodeURIComponent(params.org)}&return_to=${encodeURIComponent(returnTo)}`);
}

