"use client";

export default function ProductsError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <main className="min-h-screen bg-stone-100 px-4 py-8">
      <div className="mx-auto max-w-4xl rounded-[2rem] border border-rose-200 bg-white p-8 shadow-sm">
        <h2 className="text-2xl font-semibold text-stone-900">Products failed</h2>
        <pre className="mt-4 whitespace-pre-wrap rounded-2xl bg-rose-50 p-4 text-sm text-rose-900">
          {error.message}
        </pre>
        <button
          className="mt-5 rounded-full bg-stone-950 px-5 py-3 text-sm font-medium text-white"
          onClick={() => reset()}
        >
          Retry
        </button>
      </div>
    </main>
  );
}
