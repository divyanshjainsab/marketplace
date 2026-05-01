class ProductSerializer < BaseSerializer
  def as_json
    payload = {
      id: record.id,
      name: record.name,
      sku: record.sku,
      attributes: record.metadata,
      metadata: record.metadata,
      image_url: record.image_url,
      image: ImageAssetSerializer.one(record.image_asset),
      category: CategorySerializer.one(record.category),
      product_type: ProductTypeSerializer.one(record.product_type)
    }

    if context[:listing_count_by_product_id]
      payload[:listing_count] = (context[:listing_count_by_product_id][record.id] || 0)
    end

    if context[:include_variants]
      payload[:variants] = VariantSerializer.many(record.variants.kept.order(:name))
    end

    payload
  end
end
