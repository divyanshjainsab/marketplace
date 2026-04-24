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
        product = policy_scope(Product).find(variant_params[:product_id])
        variant = Variants::CreateOrReuse.call(
          product: product,
          attrs: variant_params.except(:image, :image_data)
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
        @variant = policy_scope(Variant).includes(product: %i[product_type category]).find(params[:id])
      end

      def variant_params
        params.require(:variant).permit(
          :product_id,
          :name,
          :sku,
          :image,
          image_data: %i[public_id optimized_url version width height],
          options: {}
        )
      end

      def attach_image_if_present(variant)
        organization = Current.organization || Current.marketplace&.organization
        raise Images::ImageUploader::InvalidUploadError, "Organization context is required for media uploads" if organization.nil?

        folder = Images::FolderPath.for(target: :variant, organization: organization)
        tags = Images::FolderPath.tags(target: :variant, organization: organization)

        image = variant_params[:image]
        if image.present?
          Images::ImageAttachment.attach_upload(
            record: variant,
            uploaded_file: image,
            folder: folder,
            tags: tags,
            delete_old: true
          )
          return
        end

        image_data = variant_params[:image_data]
        return if image_data.blank?

        Images::ImageAttachment.replace(
          record: variant,
          asset_payload: image_data,
          folder_prefix: folder,
          delete_old: true
        )
      end
    end
  end
end
