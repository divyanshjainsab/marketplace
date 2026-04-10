module Api
  module V1
    module Admin
      class MarketplacesController < BaseController
        def index
          scope = Marketplace.kept.where(organization_id: current_organization.id).order(:name)
          page = paginate(scope)
          render_collection(page, serializer: MarketplaceSerializer)
        end

        def show
          marketplace = Marketplace.kept.where(organization_id: current_organization.id).find(params[:id])
          render_resource(marketplace, serializer: MarketplaceSerializer)
        end
      end
    end
  end
end
