class CategorySerializer < BaseSerializer
  def as_json
    payload = {
      id: record.id,
      name: record.name,
      code: record.code,
      parent_id: record.parent_id
    }

    if context[:product_count_by_category_id]
      payload[:product_count] = (context[:product_count_by_category_id][record.id] || 0)
    end

    payload
  end
end
