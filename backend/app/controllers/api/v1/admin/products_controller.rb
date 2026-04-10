module Api
  module V1
    module Admin
      class ProductsController < BaseController
        def index
          listing_scope = Listing.kept.where(marketplace_id: current_marketplace.id)
          product_ids = listing_scope.select(:product_id).distinct

          listing_counts = listing_scope.group(:product_id).count

          scope = Product.kept
            .where(id: product_ids)
            .includes(:category, :product_type)
            .order(updated_at: :desc)

          page = paginate(scope)
          render_collection(page, serializer: ProductSerializer, context: { listing_count_by_product_id: listing_counts })
        end
      end
    end
  end
end

