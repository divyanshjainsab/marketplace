export default function ProductsLoading() {
  return (
    <main className="min-h-screen bg-stone-100 px-4 py-8">
      <div className="mx-auto max-w-7xl animate-pulse rounded-[2rem] bg-white p-8 shadow-sm">
        <div className="h-10 w-64 rounded-full bg-stone-200" />
        <div className="mt-8 grid gap-4 md:grid-cols-3">
          {Array.from({ length: 6 }).map((_, index) => (
            <div key={index} className="h-56 rounded-3xl bg-stone-100" />
          ))}
        </div>
      </div>
    </main>
  );
}
