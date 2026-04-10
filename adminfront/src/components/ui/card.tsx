import { cn } from "@/lib/cn";

export function Card({
  className,
  ...props
}: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn("rounded-[1.75rem] border border-slate-900/10 bg-white p-6", className)}
      {...props}
    />
  );
}

