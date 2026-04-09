class MarketplaceSerializer < BaseSerializer
  def as_json
    {
      id: record.id,
      name: record.name,
      subdomain: record.subdomain,
      organization_id: record.organization_id
    }
  end
end
