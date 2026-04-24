import type { ImageLoaderProps } from "next/image";

const CLOUDINARY_HOST_PATTERN = /^res(?:-\d+)?\.cloudinary\.com$/i;
const UPLOAD_MARKER = "/image/upload/";
const TRANSFORMATION_SEGMENT = /^[a-z0-9]+_[^/]+(?:,[a-z0-9]+_[^/]+)*$/i;

export function isCloudinaryUrl(src: string) {
  try {
    const url = new URL(src);
    return url.protocol === "https:" && CLOUDINARY_HOST_PATTERN.test(url.hostname);
  } catch {
    return false;
  }
}

export function replaceCloudinaryTransformation(src: string, transformation: string) {
  if (!isCloudinaryUrl(src)) return src;

  const [prefix, suffix] = src.split(UPLOAD_MARKER);
  if (!suffix) return src;

  const segments = suffix.split("/").filter(Boolean);
  if (segments[0] && TRANSFORMATION_SEGMENT.test(segments[0])) {
    segments.shift();
  }

  return `${prefix}${UPLOAD_MARKER}${transformation}/${segments.join("/")}`;
}

export function cloudinaryLoader({ src, width, quality }: ImageLoaderProps) {
  if (!isCloudinaryUrl(src)) return src;

  const qualityTransform = quality ? `q_${quality}` : "q_auto";
  return replaceCloudinaryTransformation(src, `c_limit,f_auto,${qualityTransform},w_${width}`);
}
