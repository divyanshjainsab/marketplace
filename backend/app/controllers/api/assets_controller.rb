module Api
  class AssetsController < BaseController
    before_action :require_user!
    before_action :require_manager!, only: :destroy

    def index
      assets = Asset.kept.order(updated_at: :desc)
      assets = assets.where(recordable_type: Array(params[:recordable_type])) if params[:recordable_type].present?

      if params[:public].present?
        assets = assets.where(market_place_id: nil)
      elsif params[:by_allies].present?
        assets = assets.where(is_network: true)
      else
        assets = assets.where(market_place_id: current_marketplace.id)
      end

      query = params[:query].to_s.strip
      if query.present? && query != "*"
        escaped = ActiveRecord::Base.sanitize_sql_like(query)
        assets = assets.where("assets.name ILIKE ?", "%#{escaped}%")
      end

      render json: {
        assets: assets.limit(250).map { |asset| render_asset(asset) }
      }
    end

    def destroy
      # Core2 scopes deletes to the current marketplace templates; keep it strict.
      Asset.kept.where(id: params[:id], market_place_id: current_marketplace.id).discard_all
      render json: {}, status: :no_content
    end

    private

    def render_asset(asset)
      {
        id: asset.id,
        name: asset.name,
        tags: Array(asset.tags),
        recordable_type: asset.recordable_type,
        recordable_id: asset.recordable_id,
        recordable_type_label: asset.recordable_type_label,
        is_promo_template: asset.is_promo_template
      }
    end
  end
end

