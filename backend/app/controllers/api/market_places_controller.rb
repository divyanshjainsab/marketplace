module Api
  class MarketPlacesController < BaseController
    before_action :require_manager!, only: :update

    def update
      ActiveRecord::Base.transaction do
        current_marketplace.market_place_option || current_marketplace.create_market_place_option!

        attrs = sanitized_market_place_params.to_h
        # Avoid runtime explosions if migrations haven't been applied yet; unknown keys are ignored.
        attrs.slice!(*current_marketplace.attribute_names)

        if current_marketplace.update(attrs)
          audit_log!(
            action: "marketplace.update",
            resource: current_marketplace,
            changes: current_marketplace.saved_changes
          )
          render json: render_market_place(current_marketplace)
        else
          render json: current_marketplace.errors, status: :unprocessable_entity
        end
      end
    end

    private

    def market_place_params
      params.require(:market_place).permit(
        :logo,
        :stored_file_id,
        :new_stored_file_id,
        :google_tracking_id,
        :pixel_tracking_id,
        :category_layout
      )
    end

    # Core2 accepts logo uploads via StoredFile; our parity layer will wire this up
    # once `/api/stored_files` exists in the target system. Until then, ignore logo keys.
    def sanitized_market_place_params
      logo_keys = %i[logo stored_file_id new_stored_file_id]
      market_place_params.except(*logo_keys)
    end

    def render_market_place(marketplace)
      option = marketplace.market_place_option
      {
        id: marketplace.id,
        user_id: nil,
        name: marketplace.name,
        name_slug: marketplace.name.to_s.parameterize,
        market_domain: marketplace.custom_domain.to_s,
        main_organization_id: marketplace.organization_id,
        google_tracking_id: marketplace.attributes["google_tracking_id"],
        pixel_tracking_id: marketplace.attributes["pixel_tracking_id"],
        category_layout: marketplace.attributes["category_layout"],
        publishable_market_place: true,
        options: option&.slice(
          :id,
          :market_place_id,
          :primary_color_main,
          :primary_color_dark,
          :secondary_color_main,
          :secondary_color_dark,
          :background_color_main,
          :background_color_dark,
          :typography_color_main,
          :typography_color_dark,
          :header_background_color_main,
          :header_background_color_dark,
          :header_typography_color_main,
          :header_typography_color_dark,
          :dark_primary_color_main,
          :dark_primary_color_dark,
          :dark_secondary_color_main,
          :dark_secondary_color_dark,
          :dark_background_color_main,
          :dark_background_color_dark,
          :dark_typography_color_main,
          :dark_typography_color_dark,
          :dark_header_background_color_main,
          :dark_header_background_color_dark,
          :dark_header_typography_color_main,
          :dark_header_typography_color_dark,
          :header_content,
          :height,
          :width,
          :use_infinite_scroll
        ),
        organization_slug: marketplace.organization&.slug,
        logo: marketplace.attributes["logo_url"].presence
      }.compact
    end
  end
end
