class ProductSuggestionSerializer < BaseSerializer
  def as_json
    {
      product_id: record.product_id,
      name: record.name,
      sku: record.sku,
      product_type: record.product_type,
      category: record.category,
      metadata: record.metadata
    }
  end
end
