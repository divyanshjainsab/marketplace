import Link from "next/link";

export default function NotAuthorizedPage() {
  return (
    <main className="mx-auto flex min-h-[60vh] max-w-md flex-col items-center justify-center px-6 py-16">
      <div className="w-full rounded-2xl border border-stone-200 bg-white p-6 shadow-sm">
        <h1 className="text-balance text-lg font-semibold text-stone-900">Not authorized</h1>
        <p className="mt-2 text-sm text-stone-600">Your account does not have access to this storefront.</p>
        <div className="mt-6 flex items-center gap-3">
          <Link
            href="/"
            className="inline-flex items-center justify-center rounded-full border border-stone-200 bg-white px-4 py-2 text-sm font-medium text-stone-700 hover:border-stone-300 hover:text-stone-900"
          >
            Go home
          </Link>
          <Link
            href="/login"
            className="inline-flex items-center justify-center rounded-full bg-stone-900 px-4 py-2 text-sm font-semibold text-stone-50 hover:bg-stone-800"
          >
            Try sign in
          </Link>
        </div>
      </div>
    </main>
  );
}

