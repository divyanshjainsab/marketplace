module Api
  module V1
    class VariantsController < BaseController
      before_action :set_variant, only: %i[show update destroy]
      before_action :require_authenticated_user!, only: %i[create update destroy]

      def index
        scope = policy_scope(Variant).includes(product: %i[product_type category]).order(:name)
        scope = scope.where(product_id: params[:product_id]) if params[:product_id].present?
        scope = scope.search_suggestions(params[:q]) if params[:q].present?

        page = paginate(scope)
        authorize Variant

        render_collection(page, serializer: VariantSerializer, context: { include_product: true })
      end

      def show
        authorize @variant
        render_resource(@variant, serializer: VariantSerializer, context: { include_product: true })
      end

      def create
        variant = Variants::CreateOrReuse.call(
          product_id: variant_params[:product_id],
          attrs: variant_params.except(:image)
        ).variant
        authorize variant
        attach_image_if_present(variant)

        render_resource(variant, serializer: VariantSerializer, status: :created, context: { include_product: true })
      end

      def update
        authorize @variant
        @variant.update!(variant_params.except(:image))
        attach_image_if_present(@variant)

        render_resource(@variant, serializer: VariantSerializer, context: { include_product: true })
      end

      def destroy
        authorize @variant
        @variant.discard
        head :no_content
      end

      private

      def set_variant
        @variant = Variant.kept.includes(product: %i[product_type category]).find(params[:id])
      end

      def variant_params
        params.require(:variant).permit(:product_id, :name, :sku, :image, options: {})
      end

      def attach_image_if_present(variant)
        image = variant_params[:image]
        return if image.blank?

        Images::ImageUploader.attach(
          record: variant,
          io: image.tempfile,
          filename: image.original_filename,
          folder: "variants",
          delete_old: true
        )
      end
    end
  end
end
