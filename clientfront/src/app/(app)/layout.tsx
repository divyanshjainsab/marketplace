import { ReactNode } from "react";
import { redirect } from "next/navigation";
import { getJwt } from "@/lib/auth";
import { AuthProvider } from "@/components/auth-provider";
import AppShell from "@/components/app-shell";

export default function AppLayout({ children }: { children: ReactNode }) {
  const jwt = getJwt();
  if (!jwt) {
    redirect("/login");
  }

  return (
    <AuthProvider>
      <AppShell>{children}</AppShell>
    </AuthProvider>
  );
}
