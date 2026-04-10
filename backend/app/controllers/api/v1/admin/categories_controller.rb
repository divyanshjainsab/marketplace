module Api
  module V1
    module Admin
      class CategoriesController < BaseController
        def index
          listing_scope = Listing.kept.where(marketplace_id: current_marketplace.id)
          product_ids = listing_scope.select(:product_id).distinct

          product_counts = Product.kept.where(id: product_ids).group(:category_id).count

          scope = Category.kept.where(id: product_counts.keys).order(:name)
          page = paginate(scope)
          render_collection(page, serializer: CategorySerializer, context: { product_count_by_category_id: product_counts })
        end
      end
    end
  end
end

