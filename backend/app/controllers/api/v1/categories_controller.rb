module Api
  module V1
    class CategoriesController < BaseController
      before_action :set_category, only: %i[show update destroy]
      before_action :require_authenticated_user!, only: %i[create update destroy]

      def index
        scope = policy_scope(Category).order(:name)
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
        params.require(:category).permit(:name, :code, :parent_id)
      end
    end
  end
end
