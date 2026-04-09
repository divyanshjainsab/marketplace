module Api
  module V1
    class ProductsController < BaseController
      before_action :set_product, only: %i[show update destroy]
      before_action :require_authenticated_user!, only: %i[create update destroy]

      def index
        scope = policy_scope(Product).includes(:product_type, :category, :variants).order(:name)
        scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?
        scope = scope.where(product_type_id: params[:product_type_id]) if params[:product_type_id].present?
        scope = scope.suggest(params[:q]) if params[:q].present?

        page = paginate(scope)
        authorize Product

        render_collection(page, serializer: ProductSerializer, context: { include_variants: true })
      end

      def suggestions
        authorize Product, :index?

        suggestions = Products::Suggest.call(
          query: params[:q],
          metadata_query: params[:metadata],
          limit: per_page_limit
        )

        render json: {
          data: suggestions.map { |suggestion| ProductSuggestionSerializer.one(suggestion) }
        }
      end

      def show
        authorize @product
        render_resource(@product, serializer: ProductSerializer, context: { include_variants: true })
      end

      def create
        authorize Product

        result = Products::CreateOrReuse.call(
          attrs: product_attrs,
          reuse_product_id: params[:reuse_product_id],
          force_create: ActiveModel::Type::Boolean.new.cast(params[:force_create]),
          suggestion_limit: per_page_limit
        )

        if result.status == :suggestions
          render json: {
            data: nil,
            meta: {
              status: result.status,
              suggestions: result.suggestions.map { |suggestion| ProductSuggestionSerializer.one(suggestion) }
            }
          }, status: :conflict
          return
        end

        attach_image_if_present(result.product)
        render_resource(result.product, serializer: ProductSerializer, status: status_for_create_or_reuse(result.status))
      end

      def update
        authorize @product
        @product.update!(product_attrs)
        attach_image_if_present(@product)

        render_resource(@product, serializer: ProductSerializer)
      end

      def destroy
        authorize @product
        @product.discard
        head :no_content
      end

      private

      def set_product
        @product = Product.kept.includes(:product_type, :category, :variants).find(params[:id])
      end

      def product_params
        params.require(:product).permit(
          :product_type_id,
          :category_id,
          :name,
          :sku,
          :image,
          metadata: {}
        )
      end

      def product_attrs
        product_params.except(:image)
      end

      def attach_image_if_present(product)
        image = product_params[:image]
        return if image.blank?

        Images::ImageUploader.attach(
          record: product,
          io: image.tempfile,
          filename: image.original_filename,
          folder: "products",
          delete_old: true
        )
      end

      def status_for_create_or_reuse(status)
        status == :created ? :created : :ok
      end
    end
  end
end
