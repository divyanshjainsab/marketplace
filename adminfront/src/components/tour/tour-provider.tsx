"use client";

import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
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

function useHighlightRect(selector: string) {
  const [rect, setRect] = useState<DOMRect | null>(null);

  useEffect(() => {
    let frame = 0;

    function update() {
      const el = document.querySelector(selector) as HTMLElement | null;
      if (!el) {
        setRect(null);
        return;
      }
      setRect(el.getBoundingClientRect());
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
  }, [selector]);

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
  const viewportWidth = typeof window === "undefined" ? 1024 : window.innerWidth;
  const viewportHeight = typeof window === "undefined" ? 768 : window.innerHeight;

  const anchorLeft = rect ? Math.max(16, Math.min(rect.left + rect.width / 2, viewportWidth - 16)) : viewportWidth / 2;
  const anchorTop = rect ? rect.bottom + 12 : 120;
  const style: React.CSSProperties = {
    left: anchorLeft,
    top: Math.min(anchorTop, viewportHeight - 16),
    transform: "translateX(-50%)",
  };

  return (
    <div className="pointer-events-auto fixed z-[1001] w-[min(420px,calc(100vw-2rem))]" style={style}>
      <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-2xl">
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

  const rect = useHighlightRect(step?.selector ?? "");

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
