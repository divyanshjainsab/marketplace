"use client";

import { cn } from "@/lib/cn";

type HeadingSize = "h1" | "h2" | "h3" | "h4";

const headingStyles: Record<HeadingSize, string> = {
  h1: "text-2xl font-semibold tracking-tight text-slate-950 sm:text-3xl",
  h2: "text-xl font-semibold tracking-tight text-slate-950 sm:text-2xl",
  h3: "text-lg font-semibold tracking-tight text-slate-950",
  h4: "text-base font-semibold tracking-tight text-slate-950",
};

export function Heading({
  as,
  size,
  className,
  ...props
}: React.HTMLAttributes<HTMLHeadingElement> & {
  as?: "h1" | "h2" | "h3" | "h4";
  size?: HeadingSize;
}) {
  const Component = as ?? (size ?? "h2");
  const resolvedSize = size ?? (Component as HeadingSize);

  return <Component className={cn(headingStyles[resolvedSize], className)} {...props} />;
}

type TextVariant = "body" | "muted" | "label" | "helper" | "kicker" | "error";
type TextAs = "p" | "span" | "div" | "label" | "small";

const textStyles: Record<TextVariant, string> = {
  body: "text-sm leading-6 text-slate-700",
  muted: "text-sm leading-6 text-slate-600",
  label: "text-sm font-semibold text-slate-900",
  helper: "text-xs leading-5 text-slate-500",
  kicker: "text-xs font-semibold uppercase tracking-[0.25em] text-slate-500",
  error: "text-sm text-rose-700",
};

export function Text({
  as: Component = "p",
  variant = "body",
  className,
  ...props
}: React.HTMLAttributes<HTMLElement> & {
  as?: TextAs;
  variant?: TextVariant;
}) {
  return <Component className={cn(textStyles[variant], className)} {...props} />;
}
