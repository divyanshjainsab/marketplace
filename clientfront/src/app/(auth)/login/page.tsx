import { redirect } from "next/navigation";

export default function LoginPage() {
  const base = process.env.NEXT_PUBLIC_SSO_URL ?? "http://sso:3000";
  const returnTo =
    process.env.NEXT_PUBLIC_APP_URL?.replace(/\/+$/, "") +
    "/callback";

  // Architecture note: to set an app-scoped httpOnly cookie, SSO must redirect back with a JWT
  // (e.g. /callback?token=...). If SSO ignores return_to, users can still login at SSO directly.
  const url = returnTo?.startsWith("http")
    ? `${base}/login?return_to=${encodeURIComponent(returnTo)}`
    : `${base}/login`;

  redirect(url);
}
