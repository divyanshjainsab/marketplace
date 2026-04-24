module Api
  class MarketPlaceOptionsController < BaseController
    before_action :require_manager!, only: :update

    def update
      option = current_marketplace.market_place_option || current_marketplace.create_market_place_option!

      if option.update(market_place_option_params)
        head :no_content
      else
        render json: option.errors, status: :unprocessable_entity
      end
    end

    private

    def market_place_option_params
      raw = params[:market_place_option].presence || params
      raw = raw.to_unsafe_h if raw.respond_to?(:to_unsafe_h)

      ActionController::Parameters
        .new(raw)
        .permit(
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
          :height,
          :width,
          :use_infinite_scroll,
          header_content: [
            {
              blocks: [
                :key,
                :text,
                :type,
                :depth,
                { inlineStyleRanges: %i[offset length style] },
                { entityRanges: %i[offset length key] },
                { data: [:"text-align"] }
              ],
              entityMap: {}
            }
          ]
        )
    end
  end
end

