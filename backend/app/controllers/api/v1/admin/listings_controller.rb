module Api
  module V1
    module Admin
      class ListingsController < BaseController
        before_action :set_listing, only: %i[update destroy]

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
          @listing.update!(listing_update_params)
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
            :currency,
            :status,
            product: %i[product_type_id category_id name sku image],
            variant: %i[name sku image],
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
          params.require(:listing).permit(:price_cents, :currency, :status)
        end

        def status_for_create_or_reuse(status)
          status == :created ? :created : :ok
        end
      end
    end
  end
end
