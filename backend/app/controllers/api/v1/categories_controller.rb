module Api
  module V1
    class CategoriesController < BaseController
      before_action :set_category, only: %i[show update destroy]
      before_action :require_authenticated_user!, only: %i[create update destroy]

      def index
        scope = policy_scope(Category).order(:name)
        scope = scope.where(product_type_id: params[:product_type_id]) if params[:product_type_id].present?
        page = paginate(scope)
        authorize Category

        render_collection(page, serializer: CategorySerializer)
      end

      def show
        authorize @category
        render_resource(@category, serializer: CategorySerializer)
      end

      def create
        category = Category.new(category_params)
        authorize category
        category.save!

        render_resource(category, serializer: CategorySerializer, status: :created)
      end

      def update
        authorize @category
        @category.update!(category_params)

        render_resource(@category, serializer: CategorySerializer)
      end

      def destroy
        authorize @category
        @category.discard
        head :no_content
      end

      private

      def set_category
        @category = policy_scope(Category).find(params[:id])
      end

      def category_params
        params.require(:category).permit(:product_type_id, :name, :code, :parent_id)
      end
    end
  end
end
