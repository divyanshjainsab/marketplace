import type { ImageLoaderProps } from "next/image";
import { cloudinaryLoader } from "./cloudinary";

export default function loader(props: ImageLoaderProps) {
  return cloudinaryLoader(props);
}
