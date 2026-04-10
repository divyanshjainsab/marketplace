import { redirect } from "next/navigation";

function sanitizeReturnTo(raw: string | null): string {
  const value = (raw ?? "").trim();
  if (!value) return "/dashboard";
  if (!value.startsWith("/")) return "/dashboard";
  if (value.startsWith("//")) return "/dashboard";
  return value;
}

export default function CallbackPage({
  searchParams,
}: {
  searchParams?: Record<string, string | string[] | undefined>;
}) {
  const returnTo = sanitizeReturnTo(typeof searchParams?.return_to === "string" ? searchParams.return_to : null);

  redirect(returnTo);
}
