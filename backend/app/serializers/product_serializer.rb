class ProductSerializer < BaseSerializer
  def as_json
    payload = {
      id: record.id,
      name: record.name,
      sku: record.sku,
      metadata: record.metadata,
      image_url: record.image_url,
      category: CategorySerializer.one(record.category),
      product_type: ProductTypeSerializer.one(record.product_type)
    }

    if context[:include_variants]
      payload[:variants] = VariantSerializer.many(record.variants.kept.order(:name))
    end

    payload
  end
end
