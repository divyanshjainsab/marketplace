class ProductTypeAttributeSerializer < BaseSerializer
  def as_json
    {
      id: record.id,
      product_type_id: record.product_type_id,
      attribute_id: record.attribute_id,
      required: record.required,
      variant_level: record.variant_level,
      position: record.position,
      config: record.config,
      attribute: CatalogAttributeSerializer.one(record.catalog_attribute)
    }
  end
end

