module Api
  module V1
    class ListingsController < BaseController
      before_action :set_listing, only: %i[show update destroy]
      before_action :require_authenticated_user!, only: %i[create update destroy]

      def index
        authorize Listing

        scope = policy_scope(Current.marketplace.listings)
          .includes(:inventory, :variant, product: %i[product_type category])
          .order(updated_at: :desc)
        scope = scope.where(status: params[:status]) if params[:status].present?
        scope = scope.where(product_id: params[:product_id]) if params[:product_id].present?
        scope = scope.where(variant_id: params[:variant_id]) if params[:variant_id].present?

        if params[:category_id].present? || params[:product_type_id].present? || params[:q].present?
          scope = scope.joins(:product)
          scope = scope.where(products: { category_id: params[:category_id] }) if params[:category_id].present?
          scope = scope.where(products: { product_type_id: params[:product_type_id] }) if params[:product_type_id].present?
          scope = scope.merge(Product.suggest(params[:q])) if params[:q].present?
        end

        page = paginate(scope)
        render_collection(page, serializer: ListingSerializer)
      end

      def show
        authorize @listing
        render_resource(@listing, serializer: ListingSerializer)
      end

      def create
        authorize Listing.new(marketplace: current_marketplace)

        result = Listings::Create.call(
          marketplace: Current.marketplace,
          params: listing_payload,
          actor: Current.user,
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

        listing = Current.marketplace.listings
          .includes(:inventory, :variant, product: %i[product_type category])
          .find(result.listing.id)

        render_resource(listing, serializer: ListingSerializer, status: status_for_create_or_reuse(result.status))
      end

      def update
        authorize @listing
        @listing.update!(listing_record_attributes)
        update_inventory_if_requested!(@listing)
        attach_listing_image_if_present(@listing)
        render_resource(@listing, serializer: ListingSerializer)
      end

      def destroy
        authorize @listing
        @listing.discard
        head :no_content
      end

      private

      def set_listing
        @listing = Current.marketplace.listings
          .kept
          .includes(:inventory, :variant, product: %i[product_type category])
          .find(params[:id])
      end

      def listing_params
        params.require(:listing).permit(
          :product_id,
          :variant_id,
          :reuse_product_id,
          :force_create,
          :price_cents,
          :inventory_count,
          :currency,
          :status,
          :image,
          image_data: %i[public_id optimized_url version width height],
          product: [
            :product_type_id,
            :category_id,
            :name,
            :sku,
            :image,
            { image_data: %i[public_id optimized_url version width height] }
          ],
          variant: [
            :name,
            :sku,
            :image,
            { image_data: %i[public_id optimized_url version width height] }
          ],
          product_metadata: {},
          variant_options: {}
        )
      end

      def listing_payload
        payload = listing_params.to_h.deep_symbolize_keys
        payload[:product] ||= {}
        payload[:variant] ||= {}
        payload[:product][:metadata] = payload.delete(:product_metadata) if payload.key?(:product_metadata)
        payload[:variant][:options] = payload.delete(:variant_options) if payload.key?(:variant_options)
        payload
      end

      def listing_update_params
        params.require(:listing).permit(
          :price_cents,
          :inventory_count,
          :currency,
          :status,
          :image,
          image_data: %i[public_id optimized_url version width height]
        )
      end

      def listing_record_attributes
        listing_update_params.except(:image, :image_data, :inventory_count)
      end

      def attach_listing_image_if_present(listing)
        organization = Current.organization || Current.marketplace&.organization
        raise Images::ImageUploader::InvalidUploadError, "Organization context is required for media uploads" if organization.nil?

        folder = Images::FolderPath.for(
          target: :listing,
          organization: organization,
          marketplace: Current.marketplace
        )
        tags = Images::FolderPath.tags(
          target: :listing,
          organization: organization,
          marketplace: Current.marketplace
        )

        image = listing_update_params[:image]
        if image.present?
          Images::ImageAttachment.attach_upload(
            record: listing,
            uploaded_file: image,
            folder: folder,
            tags: tags,
            delete_old: true,
            organization_id: organization.id,
            marketplace_id: Current.marketplace&.id,
            request_host: Current.request_host
          )
          return
        end

        image_data = listing_update_params[:image_data]
        return if image_data.blank?

        Images::ImageAttachment.replace(
          record: listing,
          asset_payload: image_data,
          folder_prefix: folder,
          delete_old: true,
          organization_id: organization.id,
          marketplace_id: Current.marketplace&.id,
          request_host: Current.request_host
        )
      end

      def update_inventory_if_requested!(listing)
        return unless listing_update_params.key?(:inventory_count)

        inventory = listing.inventory || listing.build_inventory(marketplace: Current.marketplace)
        inventory.quantity_on_hand = listing_update_params[:inventory_count].to_i
        inventory.save!
      end

      def status_for_create_or_reuse(status)
        status == :created ? :created : :ok
      end
    end
  end
end
