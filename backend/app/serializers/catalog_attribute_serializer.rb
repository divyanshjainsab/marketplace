class CatalogAttributeSerializer < BaseSerializer
  def as_json
    {
      id: record.id,
      name: record.name,
      code: record.code,
      data_type: record.data_type,
      description: record.description
    }
  end
end

