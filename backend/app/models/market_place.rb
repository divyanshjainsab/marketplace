class MarketPlace < ApplicationRecord
  self.table_name = "marketplaces"

  belongs_to :organization

  def main_organization
    organization
  end

  def market_domain
    custom_domain.to_s
  end

  def memoized_organizations_name_slugs
    [organization&.slug].compact
  end
end
