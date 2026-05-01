class VariantSerializer < BaseSerializer
  def as_json
    payload = {
      id: record.id,
      product_id: record.product_id,
      name: record.name,
      sku: record.sku,
      attributes: record.options,
      options: record.options,
      image_url: record.image_url,
      image: ImageAssetSerializer.one(record.image_asset)
    }

    if context[:include_product]
      payload[:product] = ProductSerializer.one(record.product)
    end

    payload
  end
end
