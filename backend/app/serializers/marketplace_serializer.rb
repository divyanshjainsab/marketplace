class MarketplaceSerializer < BaseSerializer
  def as_json
    {
      id: record.id,
      name: record.name,
      subdomain: record.subdomain,
      custom_domain: record.custom_domain,
      organization_id: record.organization_id
    }
  end
end
