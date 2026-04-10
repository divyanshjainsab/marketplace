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

  const returnTo = sanitizeReturnTo(searchParams?.return_to) ?? "/";

  redirect(
    `${apiBase}/auth/oidc/start/clientfront?return_to=${encodeURIComponent(returnTo)}`,
  );
}
