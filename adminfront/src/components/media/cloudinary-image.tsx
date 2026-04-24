"use client";

import Image from "next/image";
import { useState } from "react";
import { cn } from "@/lib/cn";
import type { MediaAsset } from "@/lib/types";

type CloudinaryImageProps = {
  asset?: MediaAsset | null;
  alt: string;
  className?: string;
  imageClassName?: string;
  sizes?: string;
  fill?: boolean;
  priority?: boolean;
  fallbackLabel?: string;
};

export function CloudinaryImage({
  asset,
  alt,
  className,
  imageClassName,
  sizes,
  fill = false,
  priority = false,
  fallbackLabel = "No image",
}: CloudinaryImageProps) {
  const [broken, setBroken] = useState(false);

  if (!asset || broken) {
    return (
      <div
        className={cn(
          "flex h-full min-h-[8rem] items-center justify-center rounded-2xl border border-dashed border-slate-200 bg-slate-100/80 px-3 text-center text-xs font-medium uppercase tracking-[0.2em] text-slate-400",
          className,
        )}
      >
        {fallbackLabel}
      </div>
    );
  }

  if (fill) {
    return (
      <div className={cn("relative overflow-hidden rounded-2xl bg-slate-100", className)}>
        <Image
          src={asset.optimized_url}
          alt={alt}
          fill
          sizes={sizes ?? "100vw"}
          className={cn("object-cover", imageClassName)}
          priority={priority}
          onError={() => setBroken(true)}
        />
      </div>
    );
  }

  return (
    <div className={cn("overflow-hidden rounded-2xl bg-slate-100", className)}>
      <Image
        src={asset.optimized_url}
        alt={alt}
        width={asset.width}
        height={asset.height}
        sizes={sizes}
        className={cn("h-full w-full object-cover", imageClassName)}
        priority={priority}
        onError={() => setBroken(true)}
      />
    </div>
  );
}
