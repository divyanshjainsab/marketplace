module Api
  module V1
    module Admin
      class ProductTypesController < BaseController
        before_action only: :index do
          require_admin_permission!("view_product_types")
        end
        before_action only: :create do
          require_admin_permission!("edit_product_types")
        end

        def index
          listing_scope = Listing.kept.joins(:marketplace).where(marketplaces: { organization_id: current_organization.id })
          product_ids = listing_scope.select(:product_id).distinct

          product_type_counts = Product.kept.where(id: product_ids).group(:product_type_id).count

          scope = ProductType.kept.order(:name)
          page = paginate(scope)
          render_collection(page, serializer: ProductTypeSerializer, context: { product_count_by_product_type_id: product_type_counts })
        end

        def create
          product_type = ProductType.new(product_type_params)
          authorize product_type
          product_type.save!

          render_resource(product_type, serializer: ProductTypeSerializer, status: :created)
        end

        private

        def product_type_params
          params.require(:product_type).permit(:name, :code)
        end
      end
    end
  end
end
