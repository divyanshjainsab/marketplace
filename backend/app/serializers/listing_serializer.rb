class ListingSerializer < BaseSerializer
  def as_json
    image_asset = record.effective_image_asset

    {
      id: record.id,
      marketplace_id: record.marketplace_id,
      price_cents: record.price_cents,
      currency: record.currency,
      status: record.status,
      inventory_count: record.inventory_count,
      image_url: image_asset&.dig(:optimized_url),
      image: ImageAssetSerializer.one(image_asset),
      image_source: record.effective_image_source,
      product: ProductSerializer.one(record.product),
      variant: VariantSerializer.one(record.variant),
      updated_at: record.updated_at.iso8601
    }
  end
end
