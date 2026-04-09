import type { Metadata } from "next";
import { IBM_Plex_Sans } from "next/font/google";
import "./globals.css";
import { getTenant } from "@/lib/tenant";
import { TenantProvider } from "@/components/tenant-provider";
import { ToastProvider } from "@/components/toast-provider";

const ibmPlexSans = IBM_Plex_Sans({
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
});

export const metadata: Metadata = {
  title: "Marketplace Inventory",
  description: "Tenant-aware inventory and listing operations",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const tenant = getTenant();

  return (
    <html lang="en">
      <body className={ibmPlexSans.className}>
        <TenantProvider subdomain={tenant.subdomain}>
          <ToastProvider>{children}</ToastProvider>
        </TenantProvider>
      </body>
    </html>
  );
}
