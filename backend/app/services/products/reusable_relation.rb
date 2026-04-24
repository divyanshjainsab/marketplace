module Products
  class ReusableRelation
    def self.call(organization: Current.organization, marketplace: Current.marketplace, session_org_id: Current.session_org_id)
      new(
        organization: organization,
        marketplace: marketplace,
        session_org_id: session_org_id
      ).call
    end

    def initialize(organization:, marketplace:, session_org_id:)
      @organization = organization
      @marketplace = marketplace
      @session_org_id = session_org_id
    end

    def call
      case organization&.product_sharing_scope
      when :disabled
        Product.none
      when :global
        Product.kept.where(id: Listing.kept.select(:product_id))
      else
        return Product.none unless organization_id.positive?

        listing_scope = Listing.kept.joins(:marketplace).where(marketplaces: { organization_id: organization_id })
        Product.kept.where(id: listing_scope.select(:product_id))
      end
    end

    private

    attr_reader :marketplace, :session_org_id

    def organization
      @resolved_organization ||= begin
        @organization ||
          marketplace&.organization ||
          Organization.kept.find_by(id: session_org_id)
      end
    end

    def organization_id
      organization&.id.to_i
    end
  end
end
