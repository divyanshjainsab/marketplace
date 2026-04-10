module Api
  module V1
    module Admin
      class ListingsController < BaseController
        def index
          scope = Listing.kept
            .where(marketplace_id: current_marketplace.id)
            .includes(:product, :variant)
            .order(updated_at: :desc)

          page = paginate(scope)
          render_collection(page, serializer: ListingSerializer)
        end
      end
    end
  end
end

