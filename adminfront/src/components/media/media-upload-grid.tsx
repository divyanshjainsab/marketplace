"use client";

import { useId, useRef, useState } from "react";
import { clientApiFetch } from "@/lib/client-api";
import type { MediaAsset } from "@/lib/types";
import { useToast } from "@/components/toast-provider";
import { CloudinaryImage } from "@/components/media/cloudinary-image";
import { Button } from "@/components/ui/button";
import { Text } from "@/components/ui/typography";
import { cn } from "@/lib/cn";

type MediaTarget = "product" | "variant" | "listing";

type UploadSlot = {
  key: string;
  label: string;
  hint?: string;
  target: MediaTarget;
  value: MediaAsset | null;
  error?: string;
  onChange: (asset: MediaAsset | null) => void;
};

const ACCEPTED_TYPES = "image/png,image/jpeg,image/webp,image/avif,image/gif";

function MediaUploadTile({
  slot,
  marketplaceId,
  disabled,
}: {
  slot: UploadSlot;
  marketplaceId?: number | null;
  disabled?: boolean;
}) {
  const inputId = useId();
  const inputRef = useRef<HTMLInputElement | null>(null);
  const { notify } = useToast();
  const [uploading, setUploading] = useState(false);
  const [dragging, setDragging] = useState(false);

  async function uploadFile(file: File | null | undefined) {
    if (!file) return;

    const params = new URLSearchParams({ target: slot.target });
    if (marketplaceId) params.set("marketplace_id", String(marketplaceId));

    const formData = new FormData();
    formData.append("file", file);

    setUploading(true);
    try {
      const response = await clientApiFetch<{ data: MediaAsset }>(`/v1/admin/media_assets?${params.toString()}`, {
        method: "POST",
        body: formData,
      });
      slot.onChange(response.data);
      notify(`${slot.label} uploaded`, "success");
    } catch (error) {
      notify(error instanceof Error ? error.message : `Unable to upload ${slot.label}`, "error");
    } finally {
      setUploading(false);
      setDragging(false);
      if (inputRef.current) inputRef.current.value = "";
    }
  }

  function openPicker() {
    if (disabled || uploading) return;
    inputRef.current?.click();
  }

  return (
    <div className={cn("rounded-2xl border border-slate-200 bg-white p-4", slot.error ? "border-rose-200 bg-rose-50/30" : null)}>
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <Text as="p" variant="label" className="truncate">
            {slot.label}
          </Text>
          {slot.hint ? (
            <Text as="p" variant="helper" className="mt-1">
              {slot.hint}
            </Text>
          ) : null}
        </div>
        {slot.value ? (
          <Button type="button" variant="ghost" size="sm" onClick={() => slot.onChange(null)} disabled={disabled || uploading}>
            Remove
          </Button>
        ) : null}
      </div>

      <div className="mt-4 grid gap-4 sm:grid-cols-[6rem_1fr] sm:items-start">
        <CloudinaryImage
          asset={slot.value}
          alt={slot.label}
          className="h-24 w-24"
          sizes="96px"
          fallbackLabel="No image"
        />

        <div
          role="button"
          tabIndex={disabled || uploading ? -1 : 0}
          aria-disabled={disabled || uploading}
          className={cn(
            "rounded-2xl border border-dashed px-4 py-3 text-left transition",
            dragging ? "border-slate-900 bg-slate-100" : "border-slate-300 bg-white",
            slot.error ? "border-rose-300 bg-rose-50/60" : null,
            disabled || uploading ? "cursor-not-allowed opacity-70" : "cursor-pointer hover:bg-slate-50",
          )}
          onClick={openPicker}
          onKeyDown={(event) => {
            if (event.key === "Enter" || event.key === " ") {
              event.preventDefault();
              openPicker();
            }
          }}
          onDragOver={(event) => {
            event.preventDefault();
            if (!disabled && !uploading) setDragging(true);
          }}
          onDragEnter={(event) => {
            event.preventDefault();
            if (!disabled && !uploading) setDragging(true);
          }}
          onDragLeave={(event) => {
            event.preventDefault();
            if (event.currentTarget === event.target) setDragging(false);
          }}
          onDrop={(event) => {
            event.preventDefault();
            if (disabled || uploading) return;
            uploadFile(event.dataTransfer.files?.[0]).catch(() => null);
          }}
        >
          <input
            id={inputId}
            ref={inputRef}
            type="file"
            accept={ACCEPTED_TYPES}
            disabled={disabled || uploading}
            onChange={(event) => uploadFile(event.target.files?.[0]).catch(() => null)}
            className="sr-only"
          />

          <Text as="p" variant="helper" className="uppercase tracking-[0.18em]">
            {uploading ? "Uploading…" : "Upload"}
          </Text>
          <Text as="p" variant="body" className="mt-1 text-sm text-slate-700">
            {dragging ? "Drop to upload." : slot.value ? "Replace this image." : "Choose a file or drag-and-drop."}
          </Text>
          {slot.error ? (
            <Text as="p" variant="error" className="mt-2">
              {slot.error}
            </Text>
          ) : null}
        </div>
      </div>
    </div>
  );
}

export function MediaUploadGrid({
  slots,
  marketplaceId,
  disabled,
  className,
}: {
  slots: UploadSlot[];
  marketplaceId?: number | null;
  disabled?: boolean;
  className?: string;
}) {
  const columnsClassName = slots.length <= 1 ? "md:grid-cols-1" : slots.length === 2 ? "md:grid-cols-2" : "md:grid-cols-3";

  return (
    <div className={cn("grid gap-4", columnsClassName, className)}>
      {slots.map((slot) => (
        <MediaUploadTile key={slot.key} slot={slot} marketplaceId={marketplaceId} disabled={disabled} />
      ))}
    </div>
  );
}
