module Api
  module V1
    class ProductTypesController < BaseController
      before_action :set_product_type, only: %i[show update destroy]
      before_action :require_authenticated_user!, only: %i[create update destroy]

      def index
        scope = policy_scope(ProductType).order(:name)
        page = paginate(scope)
        authorize ProductType

        render_collection(page, serializer: ProductTypeSerializer)
      end

      def show
        authorize @product_type
        render_resource(@product_type, serializer: ProductTypeSerializer)
      end

      def create
        product_type = ProductType.new(product_type_params)
        authorize product_type
        product_type.save!

        render_resource(product_type, serializer: ProductTypeSerializer, status: :created)
      end

      def update
        authorize @product_type
        @product_type.update!(product_type_params)

        render_resource(@product_type, serializer: ProductTypeSerializer)
      end

      def destroy
        authorize @product_type
        @product_type.discard
        head :no_content
      end

      private

      def set_product_type
        @product_type = ProductType.kept.find(params[:id])
      end

      def product_type_params
        params.require(:product_type).permit(:name, :code)
      end
    end
  end
end
