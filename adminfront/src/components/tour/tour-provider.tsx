"use client";

import { createContext, useCallback, useContext, useEffect, useLayoutEffect, useMemo, useRef, useState } from "react";
import { usePathname, useRouter } from "next/navigation";
import { TOUR_STEPS, TOUR_VERSION, type TourStep } from "@/components/tour/tour";
import { useWorkspace } from "@/components/providers/workspace-provider";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/cn";

type TourStatus = "idle" | "running";

type TourContextValue = {
  status: TourStatus;
  start: () => void;
  stop: () => void;
};

const TourContext = createContext<TourContextValue | null>(null);

function completionKey(orgId: number) {
  return `af_tour:${TOUR_VERSION}:org:${orgId}:completed`;
}

function readCompletion(orgId: number) {
  try {
    return window.localStorage.getItem(completionKey(orgId)) === "true";
  } catch {
    return false;
  }
}

function writeCompletion(orgId: number, completed: boolean) {
  try {
    window.localStorage.setItem(completionKey(orgId), completed ? "true" : "false");
  } catch {
    // ignore
  }
}

function useHighlightRect(selector: string, active: boolean) {
  const [rect, setRect] = useState<DOMRect | null>(null);

  useEffect(() => {
    if (!active || !selector) {
      setRect(null);
      return;
    }

    let frame = 0;
    let autoScrollAttempted = false;

    function update() {
      const candidates = Array.from(document.querySelectorAll(selector)) as HTMLElement[];
      const el = candidates.find((candidate) => {
        const box = candidate.getBoundingClientRect();
        if (box.width <= 0 && box.height <= 0) return false;
        const styles = window.getComputedStyle(candidate);
        if (styles.display === "none" || styles.visibility === "hidden") return false;
        return true;
      });

      if (!el) {
        setRect(null);
        return;
      }

      const box = el.getBoundingClientRect();

      if (!autoScrollAttempted) {
        const viewportWidth = window.innerWidth;
        const viewportHeight = window.innerHeight;
        const offscreen =
          box.bottom < 0 || box.top > viewportHeight || box.right < 0 || box.left > viewportWidth;

        if (offscreen) {
          autoScrollAttempted = true;
          try {
            el.scrollIntoView({ block: "center", inline: "nearest", behavior: "smooth" });
          } catch {
            el.scrollIntoView();
          }
          return;
        }
      }

      setRect(box);
    }

    function schedule() {
      cancelAnimationFrame(frame);
      frame = requestAnimationFrame(update);
    }

    schedule();
    window.addEventListener("resize", schedule);
    window.addEventListener("scroll", schedule, true);

    return () => {
      cancelAnimationFrame(frame);
      window.removeEventListener("resize", schedule);
      window.removeEventListener("scroll", schedule, true);
    };
  }, [active, selector]);

  return rect;
}

function Tooltip({
  step,
  rect,
  onNext,
  onBack,
  onSkip,
  canGoBack,
  isLast,
}: {
  step: TourStep;
  rect: DOMRect | null;
  onNext: () => void;
  onBack: () => void;
  onSkip: () => void;
  canGoBack: boolean;
  isLast: boolean;
}) {
  const tooltipRef = useRef<HTMLDivElement | null>(null);
  const [style, setStyle] = useState<React.CSSProperties>(() => ({ left: 16, top: 120 }));

  useLayoutEffect(() => {
    const el = tooltipRef.current;
    if (!el) return;

    const margin = 16;
    const gap = 12;

    function compute() {
      const tooltipEl = tooltipRef.current;
      if (!tooltipEl) return;

      const viewportWidth = window.innerWidth;
      const viewportHeight = window.innerHeight;
      const box = tooltipEl.getBoundingClientRect();
      const width = box.width;
      const height = box.height;

      const rectUsable = rect && rect.width > 0 && rect.height > 0 ? rect : null;

      const preferredLeft = rectUsable ? rectUsable.left + rectUsable.width / 2 - width / 2 : (viewportWidth - width) / 2;
      const left = Math.max(margin, Math.min(preferredLeft, viewportWidth - margin - width));

      const maxTop = Math.max(margin, viewportHeight - margin - height);
      const clampTop = (value: number) => Math.max(margin, Math.min(value, maxTop));

      let top = 120;
      if (rectUsable) {
        const below = rectUsable.bottom + gap;
        const above = rectUsable.top - gap - height;
        const fitsBelow = below >= margin && below + height + margin <= viewportHeight;
        const fitsAbove = above >= margin && above + height + margin <= viewportHeight;

        if (fitsBelow) top = below;
        else if (fitsAbove) top = above;
        else {
          const clampedBelow = clampTop(below);
          const clampedAbove = clampTop(above);
          top = rectUsable.top > viewportHeight / 2 ? clampedAbove : clampedBelow;
        }
      } else {
        top = clampTop(top);
      }

      setStyle({ left, top });
    }

    compute();
    window.addEventListener("resize", compute);
    window.addEventListener("scroll", compute, true);

    const resizeObserver = new ResizeObserver(() => compute());
    resizeObserver.observe(el);

    return () => {
      window.removeEventListener("resize", compute);
      window.removeEventListener("scroll", compute, true);
      resizeObserver.disconnect();
    };
  }, [rect, step.body, step.title]);

  return (
    <div
      ref={tooltipRef}
      className="pointer-events-auto fixed z-[1001] w-[min(420px,calc(100vw-2rem))] max-h-[calc(100dvh-2rem)] overflow-auto"
      style={style}
    >
      <div className="rounded-2xl border border-slate-200 bg-white p-4 shadow-2xl">
        <p className="text-xs font-semibold uppercase tracking-[0.25em] text-slate-500">Onboarding</p>
        <h3 className="mt-2 text-lg font-semibold text-slate-950">{step.title}</h3>
        <p className="mt-2 text-sm leading-6 text-slate-700">{step.body}</p>
        <div className="mt-4 flex items-center justify-between">
          <button type="button" className="text-sm font-semibold text-slate-600 hover:text-slate-900" onClick={onSkip}>
            Skip
          </button>
          <div className="flex items-center gap-2">
            {canGoBack ? (
              <Button variant="secondary" size="sm" onClick={onBack}>
                Back
              </Button>
            ) : null}
            <Button variant="primary" size="sm" onClick={onNext}>
              {isLast ? "Finish" : "Next"}
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}

function TourOverlay({
  step,
  rect,
}: {
  step: TourStep;
  rect: DOMRect | null;
}) {
  if (!rect) {
    return <div className="fixed inset-0 z-[1000] bg-slate-950/50" />;
  }

  const viewportWidth = typeof window === "undefined" ? 1024 : window.innerWidth;
  const viewportHeight = typeof window === "undefined" ? 768 : window.innerHeight;

  const pad = 10;
  const top = Math.max(8, rect.top - pad);
  const left = Math.max(8, rect.left - pad);
  const width = Math.min(viewportWidth - left - 8, rect.width + pad * 2);
  const height = Math.min(viewportHeight - top - 8, rect.height + pad * 2);

  return (
    <>
      <div className="fixed inset-0 z-[1000] bg-slate-950/55" />
      <div
        className={cn(
          "pointer-events-none fixed z-[1000] rounded-2xl ring-2 ring-white/90",
        )}
        style={{
          top,
          left,
          width,
          height,
          boxShadow: "0 0 0 9999px rgba(2, 6, 23, 0.55)",
        }}
      />
    </>
  );
}

export function TourProvider({ children }: React.PropsWithChildren) {
  const router = useRouter();
  const pathname = usePathname();
  const { adminContext, loading } = useWorkspace();

  const [status, setStatus] = useState<TourStatus>("idle");
  const [index, setIndex] = useState(0);

  const orgId = adminContext?.organization?.id ?? null;
  const step = TOUR_STEPS[index] ?? null;

  const rect = useHighlightRect(step?.selector ?? "", status === "running");

  const stop = useCallback(() => {
    setStatus("idle");
    setIndex(0);
  }, []);

  const start = useCallback(() => {
    setIndex(0);
    setStatus("running");
  }, []);

  const complete = useCallback(() => {
    if (orgId) writeCompletion(orgId, true);
    stop();
  }, [orgId, stop]);

  const skip = useCallback(() => {
    if (orgId) writeCompletion(orgId, true);
    stop();
  }, [orgId, stop]);

  const next = useCallback(() => {
    const nextIndex = index + 1;
    if (nextIndex >= TOUR_STEPS.length) {
      complete();
      return;
    }

    const nextStep = TOUR_STEPS[nextIndex];
    setIndex(nextIndex);
    if (pathname !== nextStep.route) {
      router.replace(nextStep.route);
      router.refresh();
    }
  }, [complete, index, pathname, router]);

  const back = useCallback(() => {
    const prevIndex = Math.max(index - 1, 0);
    const prevStep = TOUR_STEPS[prevIndex];
    setIndex(prevIndex);
    if (pathname !== prevStep.route) {
      router.replace(prevStep.route);
      router.refresh();
    }
  }, [index, pathname, router]);

  useEffect(() => {
    function onStart() {
      start();
    }
    window.addEventListener("adminfront:start-tour", onStart as EventListener);
    return () => window.removeEventListener("adminfront:start-tour", onStart as EventListener);
  }, [start]);

  useEffect(() => {
    if (loading) return;
    if (!orgId) return;
    if (status !== "idle") return;
    if (readCompletion(orgId)) return;

    // First-login tour trigger.
    start();
  }, [loading, orgId, start, status]);

  useEffect(() => {
    if (status !== "running") return;
    if (!step) return;
    if (pathname === step.route) return;
    router.replace(step.route);
    router.refresh();
  }, [pathname, router, status, step]);

  const value = useMemo(() => ({ status, start, stop }), [start, status, stop]);

  return (
    <TourContext.Provider value={value}>
      {children}
      {status === "running" && step ? (
        <div className="pointer-events-none">
          <TourOverlay step={step} rect={rect} />
          <Tooltip
            step={step}
            rect={rect}
            onNext={next}
            onBack={back}
            onSkip={skip}
            canGoBack={index > 0}
            isLast={index === TOUR_STEPS.length - 1}
          />
        </div>
      ) : null}
    </TourContext.Provider>
  );
}

export function useTour() {
  const context = useContext(TourContext);
  if (!context) throw new Error("useTour must be used within TourProvider");
  return context;
}
