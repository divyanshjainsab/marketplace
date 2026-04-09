class ListingSerializer < BaseSerializer
  def as_json
    {
      id: record.id,
      marketplace_id: record.marketplace_id,
      price_cents: record.price_cents,
      currency: record.currency,
      status: record.status,
      product: ProductSerializer.one(record.product),
      variant: VariantSerializer.one(record.variant),
      updated_at: record.updated_at.iso8601
    }
  end
end
