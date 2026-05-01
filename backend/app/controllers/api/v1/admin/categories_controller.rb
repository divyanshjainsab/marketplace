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

          scope = Category.kept.includes(:parent, :product_type).order(:name)
          scope = scope.where(product_type_id: params[:product_type_id]) if params[:product_type_id].present?
          page = paginate(scope)
          render_collection(page, serializer: CategorySerializer, context: { product_count_by_category_id: product_counts })
        end

        def create
          category = Category.new(category_params)
          authorize category
          ActiveRecord::Base.transaction do
            category.save!
            TenantCache.bump_namespace_version!(organization_id: current_organization.id, namespace: "admin_dashboard")
            audit_log!(
              action: "category.create",
              resource: category,
              changes: category.previous_changes,
              metadata: {
                product_type_id: category.product_type_id
              }
            )
          end

          render_resource(category, serializer: CategorySerializer, status: :created)
        end

        private

        def category_params
          params.require(:category).permit(:product_type_id, :name, :code, :parent_id)
        end
      end
    end
  end
end
