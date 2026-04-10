module Api
  module V1
    module Admin
      class MarketplacesController < BaseController
        def index
          page = paginate(Marketplace.kept.includes(:organization).order(:name))
          render_collection(page, serializer: MarketplaceSerializer)
        end

        def show
          marketplace = Marketplace.kept.find(params[:id])
          render_resource(marketplace, serializer: MarketplaceSerializer)
        end
      end
    end
  end
end

