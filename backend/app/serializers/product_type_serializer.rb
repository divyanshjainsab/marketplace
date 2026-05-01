class ProductTypeSerializer < BaseSerializer
  def as_json
    payload = {
      id: record.id,
      name: record.name,
      code: record.code
    }

    if context[:product_count_by_product_type_id]
      payload[:product_count] = (context[:product_count_by_product_type_id][record.id] || 0)
    end

    if context[:include_schema]
      product_schema = record.product_type_attributes.kept
        .where(variant_level: false)
        .includes(:catalog_attribute)
        .order(:position, :id)

      variant_schema = record.product_type_attributes.kept
        .where(variant_level: true)
        .includes(:catalog_attribute)
        .order(:position, :id)

      payload[:attributes_schema] = {
        product: ProductTypeAttributeSerializer.many(product_schema),
        variant: ProductTypeAttributeSerializer.many(variant_schema)
      }
    end

    payload
  end
end
