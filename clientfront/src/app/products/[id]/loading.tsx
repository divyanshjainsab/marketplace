export default function ProductDetailLoading() {
  return (
    <main className="px-4 py-8 md:px-6">
      <div className="mx-auto max-w-6xl animate-pulse rounded-[2rem] border border-stone-900/10 bg-white/75 p-6 shadow-[0_24px_80px_rgba(83,58,21,0.12)] backdrop-blur md:p-8">
        <div className="grid gap-10 lg:grid-cols-[1.05fr_0.95fr]">
          <div className="space-y-4">
            <div className="h-5 w-40 rounded-full bg-stone-200" />
            <div className="h-[22rem] rounded-3xl bg-stone-100 md:h-[28rem]" />
          </div>
          <div className="space-y-5">
            <div className="h-8 w-3/4 rounded-2xl bg-stone-200" />
            <div className="h-5 w-40 rounded-full bg-stone-200" />
            <div className="h-28 rounded-3xl bg-stone-100" />
            <div className="h-36 rounded-3xl bg-stone-100" />
            <div className="h-12 rounded-2xl bg-stone-200" />
          </div>
        </div>
      </div>
    </main>
  );
}

