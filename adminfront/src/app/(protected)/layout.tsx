import { ReactNode } from "react";
import AppShell from "@/components/layout/app-shell";
import { WorkspaceProvider } from "@/components/providers/workspace-provider";
import { TourProvider } from "@/components/tour/tour-provider";

export default function ProtectedLayout({ children }: { children: ReactNode }) {
  return (
    <WorkspaceProvider>
      <TourProvider>
        <AppShell>{children}</AppShell>
      </TourProvider>
    </WorkspaceProvider>
  );
}
