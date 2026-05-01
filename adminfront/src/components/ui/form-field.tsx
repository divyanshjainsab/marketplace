"use client";

import { useId } from "react";
import { cn } from "@/lib/cn";
import { Text } from "@/components/ui/typography";

type ControlRenderProps = {
  id: string;
  describedBy?: string;
  invalid: boolean;
};

export function FormField({
  id,
  label,
  hint,
  error,
  required,
  className,
  children,
}: {
  id?: string;
  label: string;
  hint?: string;
  error?: string;
  required?: boolean;
  className?: string;
  children: (control: ControlRenderProps) => React.ReactNode;
}) {
  const autoId = useId();
  const controlId = (id ?? autoId).replace(/:/g, "");
  const hintId = hint ? `${controlId}-hint` : undefined;
  const errorId = error ? `${controlId}-error` : undefined;
  const describedBy = [hintId, errorId].filter(Boolean).join(" ") || undefined;

  return (
    <div className={cn("space-y-2", className)}>
      <label htmlFor={controlId} className="block">
        <Text as="span" variant="label">
          {label}
          {required ? <span className="text-slate-500"> *</span> : null}
        </Text>
      </label>

      {children({ id: controlId, describedBy, invalid: Boolean(error) })}

      {hint ? (
        <Text id={hintId} variant="helper">
          {hint}
        </Text>
      ) : null}

      {error ? (
        <Text id={errorId} variant="error">
          {error}
        </Text>
      ) : null}
    </div>
  );
}

