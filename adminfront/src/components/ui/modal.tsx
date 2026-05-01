"use client";

import { useEffect, useMemo, useRef } from "react";
import { createPortal } from "react-dom";
import { cn } from "@/lib/cn";
import { Button } from "@/components/ui/button";
import { Heading, Text } from "@/components/ui/typography";

type ModalSize = "sm" | "md" | "lg";

const maxWidthBySize: Record<ModalSize, string> = {
  sm: "max-w-md",
  md: "max-w-xl",
  lg: "max-w-2xl",
};

function getFocusable(container: HTMLElement | null) {
  if (!container) return [];
  const selector =
    'a[href],button:not([disabled]),textarea:not([disabled]),input:not([disabled]),select:not([disabled]),[tabindex]:not([tabindex="-1"])';
  return Array.from(container.querySelectorAll<HTMLElement>(selector)).filter((el) => !el.hasAttribute("disabled"));
}

export function Modal({
  open,
  onClose,
  title,
  description,
  children,
  footer,
  size = "md",
  showClose = true,
}: {
  open: boolean;
  onClose: () => void;
  title?: string;
  description?: string;
  children: React.ReactNode;
  footer?: React.ReactNode;
  size?: ModalSize;
  showClose?: boolean;
}) {
  const dialogRef = useRef<HTMLDivElement | null>(null);
  const previousActive = useRef<HTMLElement | null>(null);

  const ids = useMemo(() => {
    const key = Math.random().toString(36).slice(2);
    return {
      title: `modal-title-${key}`,
      description: `modal-description-${key}`,
    };
  }, []);

  useEffect(() => {
    if (!open) return;

    previousActive.current = document.activeElement as HTMLElement | null;
    const prevOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";

    const timer = window.setTimeout(() => {
      const focusables = getFocusable(dialogRef.current);
      (focusables[0] ?? dialogRef.current)?.focus();
    }, 0);

    function onKeyDown(event: KeyboardEvent) {
      if (event.key === "Escape") {
        event.preventDefault();
        onClose();
        return;
      }

      if (event.key !== "Tab") return;

      const focusables = getFocusable(dialogRef.current);
      if (!focusables.length) {
        event.preventDefault();
        return;
      }

      const currentIndex = focusables.indexOf(document.activeElement as HTMLElement);
      const lastIndex = focusables.length - 1;

      if (event.shiftKey) {
        if (currentIndex <= 0) {
          event.preventDefault();
          focusables[lastIndex]?.focus();
        }
      } else {
        if (currentIndex === lastIndex) {
          event.preventDefault();
          focusables[0]?.focus();
        }
      }
    }

    window.addEventListener("keydown", onKeyDown);

    return () => {
      window.clearTimeout(timer);
      window.removeEventListener("keydown", onKeyDown);
      document.body.style.overflow = prevOverflow;
      previousActive.current?.focus?.();
      previousActive.current = null;
    };
  }, [onClose, open]);

  if (!open) return null;

  return createPortal(
    <div className="fixed inset-0 z-50 flex items-end justify-center p-4 sm:items-center">
      <button
        type="button"
        aria-label="Close dialog"
        className="absolute inset-0 bg-slate-950/40"
        onClick={onClose}
      />
      <div
        ref={dialogRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby={title ? ids.title : undefined}
        aria-describedby={description ? ids.description : undefined}
        tabIndex={-1}
        className={cn(
          "relative z-10 w-full rounded-2xl border border-slate-200 bg-white shadow-2xl outline-none",
          maxWidthBySize[size],
        )}
      >
        {(title || description || showClose) ? (
          <div className="flex items-start justify-between gap-4 border-b border-slate-200 px-6 py-4">
            <div className="min-w-0">
              {title ? (
                <Heading as="h2" size="h3" id={ids.title} className="truncate">
                  {title}
                </Heading>
              ) : null}
              {description ? (
                <Text id={ids.description} variant="muted" className="mt-1">
                  {description}
                </Text>
              ) : null}
            </div>
            {showClose ? (
              <Button type="button" variant="ghost" size="sm" onClick={onClose}>
                Close
              </Button>
            ) : null}
          </div>
        ) : null}

        <div className="px-6 py-4">{children}</div>

        {footer ? <div className="border-t border-slate-200 px-6 py-4">{footer}</div> : null}
      </div>
    </div>,
    document.body,
  );
}

export function ConfirmDialog({
  open,
  title,
  description,
  confirmLabel = "Confirm",
  cancelLabel = "Cancel",
  confirming,
  tone = "danger",
  onConfirm,
  onClose,
}: {
  open: boolean;
  title: string;
  description?: string;
  confirmLabel?: string;
  cancelLabel?: string;
  confirming?: boolean;
  tone?: "danger" | "primary";
  onConfirm: () => void;
  onClose: () => void;
}) {
  return (
    <Modal
      open={open}
      onClose={onClose}
      title={title}
      description={description}
      footer={
        <div className="flex flex-col gap-2 sm:flex-row sm:justify-end">
          <Button type="button" variant="secondary" onClick={onClose} disabled={confirming}>
            {cancelLabel}
          </Button>
          <Button type="button" variant={tone === "primary" ? "primary" : "danger"} onClick={onConfirm} disabled={confirming}>
            {confirming ? "Working..." : confirmLabel}
          </Button>
        </div>
      }
    >
      <Text variant="muted">{description ?? "This action cannot be undone."}</Text>
    </Modal>
  );
}

