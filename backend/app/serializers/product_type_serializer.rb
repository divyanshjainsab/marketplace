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

    payload
  end
end
