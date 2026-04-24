module Api
  module V1
    module Admin
      class ListingsController < BaseController
        before_action :set_listing, only: %i[update destroy]
        before_action only: :index do
          require_admin_permission!("view_listings")
        end
        before_action only: %i[create update destroy] do
          require_admin_permission!("edit_listings")
        end

        def index
          scope = Listing.kept
            .where(marketplace_id: current_marketplace.id)
            .includes(:variant, product: %i[product_type category])
            .order(updated_at: :desc)

          page = paginate(scope)
          render_collection(page, serializer: ListingSerializer)
        end

        def create
          authorize Listing.new(marketplace: current_marketplace)

          result = Listings::Create.call(
            marketplace: current_marketplace,
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

          listing = Listing.kept
            .where(marketplace_id: current_marketplace.id)
            .includes(:variant, product: %i[product_type category])
            .find(result.listing.id)

          render_resource(listing, serializer: ListingSerializer, status: status_for_create_or_reuse(result.status))
        end

        def update
          authorize @listing
          @listing.update!(listing_record_attributes)
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
          @listing = Listing.kept
            .where(marketplace_id: current_marketplace.id)
            .includes(:variant, product: %i[product_type category])
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
          listing_update_params.except(:image, :image_data)
        end

        def attach_listing_image_if_present(listing)
          folder = Images::FolderPath.for(
            target: :listing,
            organization: current_organization,
            marketplace: current_marketplace
          )
          tags = Images::FolderPath.tags(
            target: :listing,
            organization: current_organization,
            marketplace: current_marketplace
          )

          image = listing_update_params[:image]
          if image.present?
            Images::ImageAttachment.attach_upload(
              record: listing,
              uploaded_file: image,
              folder: folder,
              tags: tags,
              delete_old: true
            )
            return
          end

          image_data = listing_update_params[:image_data]
          return if image_data.blank?

          Images::ImageAttachment.replace(
            record: listing,
            asset_payload: image_data,
            folder_prefix: folder,
            delete_old: true
          )
        end

        def status_for_create_or_reuse(status)
          status == :created ? :created : :ok
        end
      end
    end
  end
end
