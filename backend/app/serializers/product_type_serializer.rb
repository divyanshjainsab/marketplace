class ProductTypeSerializer < BaseSerializer
  def as_json
    {
      id: record.id,
      name: record.name,
      code: record.code
    }
  end
end
