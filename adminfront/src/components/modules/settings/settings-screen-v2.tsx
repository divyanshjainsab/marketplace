"use client";

import { useEffect, useMemo, useState } from "react";
import { clientApiFetch } from "@/lib/client-api";
import type { AdminSettings, AdminSettingsResponse } from "@/lib/types";
import { MediaUploadField } from "@/components/media/media-upload-field";
import { useWorkspace } from "@/components/providers/workspace-provider";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { FormField } from "@/components/ui/form-field";
import { Input } from "@/components/ui/input";
import { PageHeader } from "@/components/ui/page-header";
import { Select } from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import { Textarea } from "@/components/ui/textarea";
import { Heading, Text } from "@/components/ui/typography";

const DEFAULT_SETTINGS: AdminSettings = {
  general: {
    store_name: "",
    branding: "",
    logo: null,
  },
  product_settings: {
    allow_product_sharing: true,
    isolation_mode: false,
  },
  integrations: {
    google_analytics_id: "",
    meta_pixel_id: "",
    future_api_notes: "",
  },
};

function sharingScopeLabel(settings: AdminSettings) {
  if (!settings.product_settings.allow_product_sharing) return "Sharing disabled";
  if (settings.product_settings.isolation_mode) return "Organization-only sharing";
  return "Global sharing enabled";
}

export function SettingsScreenV2() {
  const { session, adminContext, activeOrganization, activeMarketplace, currentRole, permissions, loading, activeMarketplaceId } =
    useWorkspace();
  const [settings, setSettings] = useState<AdminSettings>(DEFAULT_SETTINGS);
  const [loadingSettings, setLoadingSettings] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const canEditSettings = useMemo(
    () => permissions.includes("manage_organization") || permissions.includes("edit_market_places"),
    [permissions],
  );

  useEffect(() => {
    if (!activeMarketplaceId) return;

    let active = true;
    setLoadingSettings(true);
    setError(null);

    clientApiFetch<AdminSettingsResponse>(`/v1/admin/settings?marketplace_id=${activeMarketplaceId}`)
      .then((response) => {
        if (!active) return;
        setSettings(response.data.settings);
      })
      .catch((fetchError) => {
        if (!active) return;
        setError(fetchError instanceof Error ? fetchError.message : "Unable to load settings");
      })
      .finally(() => {
        if (active) setLoadingSettings(false);
      });

    return () => {
      active = false;
    };
  }, [activeMarketplaceId]);

  async function saveSettings() {
    if (!activeMarketplaceId) return;

    setSaving(true);
    setError(null);

    try {
      const response = await clientApiFetch<AdminSettingsResponse>(`/v1/admin/settings?marketplace_id=${activeMarketplaceId}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ settings }),
      });

      setSettings(response.data.settings);
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : "Unable to save settings");
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        kicker="Settings"
        title="Organization settings"
        description="Saved once per organization and applied across the admin panel, including product reuse behavior."
        actions={
          <div className="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-700">
            <Text variant="kicker" className="text-slate-500">
              Active scope
            </Text>
            <p className="mt-2 font-semibold text-slate-950">{sharingScopeLabel(settings)}</p>
            <p className="mt-1 text-xs text-slate-500">{activeMarketplace?.name ?? "No store selected"}</p>
          </div>
        }
      />

      {error ? (
        <Card className="border-rose-200 bg-rose-50 text-rose-900">
          <p className="text-sm font-semibold">{error}</p>
        </Card>
      ) : null}

      <section className="grid gap-4 md:grid-cols-2">
        <Card className="bg-slate-50">
          <p className="text-xs font-semibold uppercase tracking-[0.25em] text-slate-500">Organization</p>
          {loading ? (
            <div className="mt-3 space-y-2">
              <Skeleton className="h-4 w-48" />
              <Skeleton className="h-4 w-32" />
            </div>
          ) : (
            <div className="mt-3 space-y-1 text-sm text-slate-700">
              <p className="font-semibold text-slate-950">{activeOrganization?.name ?? adminContext?.organization?.name ?? session?.organization?.name}</p>
              <p className="text-xs text-slate-500">Slug: {activeOrganization?.slug ?? adminContext?.organization?.slug ?? session?.organization?.slug}</p>
              <p className="text-xs text-slate-500">Store: {activeMarketplace?.name ?? "No store selected"}</p>
            </div>
          )}
        </Card>

        <Card className="bg-slate-50">
          <p className="text-xs font-semibold uppercase tracking-[0.25em] text-slate-500">Admin profile</p>
          {loading ? (
            <div className="mt-3 space-y-2">
              <Skeleton className="h-4 w-56" />
              <Skeleton className="h-4 w-40" />
            </div>
          ) : (
            <div className="mt-3 space-y-1 text-sm text-slate-700">
              <p className="font-semibold text-slate-950">{session?.user?.name ?? "Admin"}</p>
              <p className="text-xs text-slate-500">{session?.user?.email}</p>
              <p className="text-xs text-slate-500">Role: {currentRole ?? "none"}</p>
              <p className="text-xs text-slate-500">Permissions: {permissions.join(", ") || "none"}</p>
            </div>
          )}
        </Card>
      </section>

      <div className="grid gap-6 xl:grid-cols-[minmax(0,1.1fr)_minmax(0,0.9fr)]">
        <div className="space-y-6">
          <Card>
            <Text variant="kicker">General</Text>
            <Heading as="h2" size="h3" className="mt-2">
              Store name, logo, and branding
            </Heading>

            {loadingSettings ? (
              <div className="mt-6 space-y-3">
                <Skeleton className="h-11 w-full" />
                <Skeleton className="h-32 w-full" />
                <Skeleton className="h-48 w-full" />
              </div>
            ) : (
              <div className="mt-6 space-y-4">
                <FormField label="Store name" hint="Used as the organization-level display name for this admin workspace.">
                  {({ id, describedBy }) => (
                    <Input
                      id={id}
                      aria-describedby={describedBy}
                      value={settings.general.store_name}
                      onChange={(event) =>
                        setSettings((current) => ({
                          ...current,
                          general: { ...current.general, store_name: event.target.value },
                        }))
                      }
                      placeholder="Organization 1 Control Room"
                      disabled={!activeMarketplaceId || !canEditSettings || saving}
                    />
                  )}
                </FormField>

                <FormField
                  label="Branding notes"
                  hint="Describe the tone or brand rules that admins should follow across the organization."
                >
                  {({ id, describedBy }) => (
                    <Textarea
                      id={id}
                      aria-describedby={describedBy}
                      value={settings.general.branding}
                      onChange={(event) =>
                        setSettings((current) => ({
                          ...current,
                          general: { ...current.general, branding: event.target.value },
                        }))
                      }
                      placeholder="Global catalog enabled for collaborative merchandising."
                      disabled={!activeMarketplaceId || !canEditSettings || saving}
                    />
                  )}
                </FormField>

                <MediaUploadField
                  label="Organization logo"
                  hint="Stored in Cloudinary and reused anywhere this organization needs branding."
                  target="site_editor"
                  marketplaceId={activeMarketplaceId}
                  value={settings.general.logo ?? null}
                  disabled={!activeMarketplaceId || !canEditSettings || saving}
                  onChange={(asset) =>
                    setSettings((current) => ({
                      ...current,
                      general: { ...current.general, logo: asset },
                    }))
                  }
                />
              </div>
            )}
          </Card>

          <Card>
            <Text variant="kicker">Integrations</Text>
            <Heading as="h2" size="h3" className="mt-2">
              Analytics and future APIs
            </Heading>

            {loadingSettings ? (
              <div className="mt-6 space-y-3">
                <Skeleton className="h-11 w-full" />
                <Skeleton className="h-11 w-full" />
                <Skeleton className="h-32 w-full" />
              </div>
            ) : (
              <div className="mt-6 space-y-4">
                <FormField label="Google Analytics ID" hint="Optional. Example: G-XXXXXXX.">
                  {({ id, describedBy }) => (
                    <Input
                      id={id}
                      aria-describedby={describedBy}
                      value={settings.integrations.google_analytics_id}
                      onChange={(event) =>
                        setSettings((current) => ({
                          ...current,
                          integrations: { ...current.integrations, google_analytics_id: event.target.value },
                        }))
                      }
                      placeholder="G-ORG1ADMIN"
                      disabled={!activeMarketplaceId || !canEditSettings || saving}
                    />
                  )}
                </FormField>

                <FormField label="Meta Pixel ID" hint="Optional. Example: PIXEL-ORG1.">
                  {({ id, describedBy }) => (
                    <Input
                      id={id}
                      aria-describedby={describedBy}
                      value={settings.integrations.meta_pixel_id}
                      onChange={(event) =>
                        setSettings((current) => ({
                          ...current,
                          integrations: { ...current.integrations, meta_pixel_id: event.target.value },
                        }))
                      }
                      placeholder="PIXEL-ORG1"
                      disabled={!activeMarketplaceId || !canEditSettings || saving}
                    />
                  )}
                </FormField>

                <FormField label="Future API notes" hint="Track placeholder integration requirements or upcoming API work.">
                  {({ id, describedBy }) => (
                    <Textarea
                      id={id}
                      aria-describedby={describedBy}
                      value={settings.integrations.future_api_notes}
                      onChange={(event) =>
                        setSettings((current) => ({
                          ...current,
                          integrations: { ...current.integrations, future_api_notes: event.target.value },
                        }))
                      }
                      placeholder="Reserved for ERP, analytics, or marketplace sync integrations."
                      disabled={!activeMarketplaceId || !canEditSettings || saving}
                    />
                  )}
                </FormField>
              </div>
            )}
          </Card>
        </div>

        <div className="space-y-6">
          <Card>
            <Text variant="kicker">Product settings</Text>
            <Heading as="h2" size="h3" className="mt-2">
              Sharing and isolation
            </Heading>

            {loadingSettings ? (
              <div className="mt-6 space-y-3">
                <Skeleton className="h-11 w-full" />
                <Skeleton className="h-11 w-full" />
                <Skeleton className="h-24 w-full" />
              </div>
            ) : (
              <div className="mt-6 space-y-4">
                <FormField
                  label="Allow product sharing"
                  hint="Turn this off to force every listing flow to create a new product record."
                >
                  {({ id, describedBy }) => (
                    <Select
                      id={id}
                      aria-describedby={describedBy}
                      value={settings.product_settings.allow_product_sharing ? "true" : "false"}
                      onChange={(event) =>
                        setSettings((current) => ({
                          ...current,
                          product_settings: {
                            ...current.product_settings,
                            allow_product_sharing: event.target.value === "true",
                          },
                        }))
                      }
                      disabled={!activeMarketplaceId || !canEditSettings || saving}
                    >
                      <option value="true">Enabled</option>
                      <option value="false">Disabled</option>
                    </Select>
                  )}
                </FormField>

                <FormField
                  label="Isolation mode"
                  hint="When enabled, reuse is limited to this organization. When disabled, global product reuse is allowed."
                >
                  {({ id, describedBy }) => (
                    <Select
                      id={id}
                      aria-describedby={describedBy}
                      value={settings.product_settings.isolation_mode ? "true" : "false"}
                      onChange={(event) =>
                        setSettings((current) => ({
                          ...current,
                          product_settings: {
                            ...current.product_settings,
                            isolation_mode: event.target.value === "true",
                          },
                        }))
                      }
                      disabled={!activeMarketplaceId || !canEditSettings || saving}
                    >
                      <option value="true">Enabled</option>
                      <option value="false">Disabled</option>
                    </Select>
                  )}
                </FormField>

                <div className="rounded-2xl border border-slate-200 bg-slate-50 px-4 py-4 text-sm text-slate-700">
                  <p className="font-semibold text-slate-950">Current behavior</p>
                  <p className="mt-2">
                    {!settings.product_settings.allow_product_sharing
                      ? "Admins cannot reuse shared products from the listing flow."
                      : settings.product_settings.isolation_mode
                        ? "Admins can reuse products inside this organization, but not from the global catalog."
                        : "Admins can receive suggestions from the wider shared catalog and reuse them directly."}
                  </p>
                </div>
              </div>
            )}
          </Card>

          <Card className="bg-slate-50">
            <p className="text-xs font-semibold uppercase tracking-[0.25em] text-slate-500">Access</p>
            <div className="mt-3 space-y-2 text-sm text-slate-700">
              <p>Only admin-authorized users can reach `adminfront`.</p>
              <p>Backend permissions still gate writes for listings, taxonomy, settings, and site editor actions.</p>
              <p>Selected organization and marketplace are validated server-side before data is returned.</p>
            </div>
          </Card>
        </div>
      </div>

      <div className="flex flex-col gap-3 sm:flex-row">
        <Button type="button" variant="primary" onClick={() => saveSettings().catch(() => null)} disabled={!activeMarketplaceId || !canEditSettings || saving || loadingSettings}>
          {saving ? "Saving..." : "Save settings"}
        </Button>
        <Button
          type="button"
          variant="secondary"
          onClick={() => {
            if (!activeMarketplaceId) return;
            setLoadingSettings(true);
            clientApiFetch<AdminSettingsResponse>(`/v1/admin/settings?marketplace_id=${activeMarketplaceId}`)
              .then((response) => setSettings(response.data.settings))
              .catch((reloadError) => setError(reloadError instanceof Error ? reloadError.message : "Unable to reload settings"))
              .finally(() => setLoadingSettings(false));
          }}
          disabled={loadingSettings || saving}
        >
          Reload
        </Button>
      </div>
    </div>
  );
}
