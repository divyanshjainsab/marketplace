import { ReactNode } from "react";
import { AuthProvider } from "@/components/auth-provider";
import AppShell from "@/components/app-shell";

export default function AppLayout({ children }: { children: ReactNode }) {
  return (
    <AuthProvider>
      <AppShell>{children}</AppShell>
    </AuthProvider>
  );
}

