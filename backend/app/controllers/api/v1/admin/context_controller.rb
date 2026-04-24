module Api
  module V1
    module Admin
      class ContextController < BaseController
        def show
          marketplaces = Marketplace.kept.where(organization_id: current_organization.id).order(:name)
          organizations = available_organizations.order(:name, :id)

          render json: {
            data: {
              organization: OrganizationSerializer.one(current_organization),
              organizations: organizations.map { |organization| OrganizationSerializer.one(organization) },
              marketplaces: marketplaces.map { |m| MarketplaceSerializer.one(m) }
            }
          }
        end
      end
    end
  end
end
