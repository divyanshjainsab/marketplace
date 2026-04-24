module Api
  module V1
    module Admin
      class CategoriesController < BaseController
        before_action only: :index do
          require_admin_permission!("view_categories")
        end
        before_action only: :create do
          require_admin_permission!("edit_categories")
        end

        def index
          listing_scope = Listing.kept.joins(:marketplace).where(marketplaces: { organization_id: current_organization.id })
          product_ids = listing_scope.select(:product_id).distinct

          product_counts = Product.kept.where(id: product_ids).group(:category_id).count

          scope = Category.kept.includes(:parent).order(:name)
          page = paginate(scope)
          render_collection(page, serializer: CategorySerializer, context: { product_count_by_category_id: product_counts })
        end

        def create
          category = Category.new(category_params)
          authorize category
          category.save!

          render_resource(category, serializer: CategorySerializer, status: :created)
        end

        private

        def category_params
          params.require(:category).permit(:name, :code, :parent_id)
        end
      end
    end
  end
end
