"use client";

import { useId, useRef, useState } from "react";
import { clientApiFetch } from "@/lib/client-api";
import type { MediaAsset } from "@/lib/types";
import { useToast } from "@/components/toast-provider";
import { Button } from "@/components/ui/button";
import { CloudinaryImage } from "./cloudinary-image";

type MediaTarget = "product" | "variant" | "listing" | "site_editor";

type MediaUploadFieldProps = {
  label: string;
  hint?: string;
  target: MediaTarget;
  marketplaceId?: number | null;
  value?: MediaAsset | null;
  disabled?: boolean;
  error?: string;
  onChange: (asset: MediaAsset | null) => void;
};

const ACCEPTED_TYPES = "image/png,image/jpeg,image/webp,image/avif,image/gif";

export function MediaUploadField({
  label,
  hint,
  target,
  marketplaceId,
  value,
  disabled = false,
  error,
  onChange,
}: MediaUploadFieldProps) {
  const inputId = useId();
  const inputRef = useRef<HTMLInputElement | null>(null);
  const { notify } = useToast();
  const [uploading, setUploading] = useState(false);
  const [dragging, setDragging] = useState(false);

  async function uploadFile(file: File | null | undefined) {
    if (!file) return;

    const params = new URLSearchParams({ target });
    if (marketplaceId) params.set("marketplace_id", String(marketplaceId));

    const formData = new FormData();
    formData.append("file", file);

    setUploading(true);
    try {
      const response = await clientApiFetch<{ data: MediaAsset }>(`/v1/admin/media_assets?${params.toString()}`, {
        method: "POST",
        body: formData,
      });
      onChange(response.data);
      notify("Image uploaded", "success");
    } catch (error) {
      notify(error instanceof Error ? error.message : "Unable to upload image", "error");
    } finally {
      setUploading(false);
      setDragging(false);
      if (inputRef.current) inputRef.current.value = "";
    }
  }

  function handleFileChange(event: React.ChangeEvent<HTMLInputElement>) {
    uploadFile(event.target.files?.[0]).catch(() => null);
  }

  return (
    <div className="rounded-3xl border border-slate-200 bg-slate-50 p-4 sm:p-5">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <label htmlFor={inputId} className="text-sm font-semibold text-slate-900">
            {label}
          </label>
          {hint ? <p className="mt-1 text-xs leading-5 text-slate-500">{hint}</p> : null}
        </div>
        {value ? (
          <Button type="button" variant="ghost" size="sm" onClick={() => onChange(null)} disabled={disabled || uploading}>
            Remove
          </Button>
        ) : null}
      </div>

      <div className="mt-4 grid gap-4 md:grid-cols-[minmax(0,11rem)_1fr]">
        <CloudinaryImage
          asset={value}
          alt={label}
          className="h-40 w-full"
          sizes="(max-width: 767px) 100vw, 176px"
          fallbackLabel="Awaiting upload"
        />

        <div
          className={`rounded-2xl border border-dashed p-4 transition sm:p-5 ${
            dragging ? "border-slate-900 bg-slate-100" : "border-slate-300 bg-white"
          } ${error ? "border-rose-300 bg-rose-50/70" : ""}`}
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
            onChange={handleFileChange}
            className="sr-only"
          />

          <div className="flex h-full flex-col justify-between gap-4">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500">Cloudinary upload</p>
              <p className="mt-2 text-sm text-slate-700">
                {dragging
                  ? "Drop the image to upload it."
                  : "Drag and drop an image here, or choose one from this device."}
              </p>
            </div>

            <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
              <Button
                type="button"
                variant="primary"
                onClick={() => inputRef.current?.click()}
                disabled={disabled || uploading}
                className="w-full sm:w-auto"
              >
                {uploading ? "Uploading..." : value ? "Replace image" : "Choose image"}
              </Button>
              <p className="text-xs leading-5 text-slate-500">
                PNG, JPG, WEBP, AVIF, and GIF are supported. Images are stored in Cloudinary and delivered from the CDN.
              </p>
            </div>

            <div className="rounded-2xl bg-slate-50 px-4 py-3 text-xs text-slate-600">
              {uploading
                ? "Uploading to Cloudinary and generating versioned delivery URLs..."
                : value
                  ? `Cloudinary v${value.version} • ${value.width}×${value.height}`
                  : "No image uploaded yet."}
            </div>
          </div>
        </div>
      </div>

      {error ? <p className="mt-3 text-sm text-rose-700">{error}</p> : null}
    </div>
  );
}
