export function formatInrFromCents(priceCents: number | null | undefined): string {
  if (priceCents == null) return "Not set";

  return new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency: "INR",
  }).format(priceCents / 100);
}
