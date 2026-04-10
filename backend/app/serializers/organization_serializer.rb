class OrganizationSerializer < BaseSerializer
  def as_json
    {
      id: record.id,
      name: record.name,
      slug: record.slug
    }
  end
end

