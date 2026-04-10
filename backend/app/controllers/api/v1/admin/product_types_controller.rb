module Api
  module V1
    module Admin
      class ProductTypesController < BaseController
        def index
          listing_scope = Listing.kept.where(marketplace_id: current_marketplace.id)
          product_ids = listing_scope.select(:product_id).distinct

          product_type_counts = Product.kept.where(id: product_ids).group(:product_type_id).count

          scope = ProductType.kept.where(id: product_type_counts.keys).order(:name)
          page = paginate(scope)
          render_collection(page, serializer: ProductTypeSerializer, context: { product_count_by_product_type_id: product_type_counts })
        end
      end
    end
  end
end

