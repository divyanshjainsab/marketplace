module Api
  module V2
    class AssetsController < BaseController
      before_action :require_manager!, except: %i[index show]
      before_action :set_page
      before_action :set_asset, only: :show

      def index
        assets = Asset.kept.where(market_place_id: current_marketplace.id).order(updated_at: :desc)
        render json: {
          assets: assets.map do |asset|
            {
              id: asset.id,
              name: asset.name,
              tags: Array(asset.tags),
              recordable_type: asset.recordable_type,
              recordable_id: asset.recordable_id,
              is_network: asset.is_network,
              is_promo_template: asset.is_promo_template,
              recordable_type_label: asset.recordable_type_label
            }
          end
        }
      end

      def create
        asset = Asset.create!(
          name: asset_params[:name],
          tags: Array(asset_params[:tags]),
          recordable: resolve_recordable,
          market_place_id: asset_market_place_id,
          is_network: ActiveModel::Type::Boolean.new.cast(params[:public]) || ActiveModel::Type::Boolean.new.cast(asset_params[:is_network]),
          is_promo_template: ActiveModel::Type::Boolean.new.cast(asset_params[:is_promo_template])
        )

        audit_log!(
          action: "asset.create",
          resource: asset,
          changes: asset.previous_changes,
          metadata: {
            market_place_id: current_marketplace.id,
            public: ActiveModel::Type::Boolean.new.cast(params[:public])
          }
        )

        render json: render_asset(asset), status: :created
      end

      def show
        recordable = @asset.recordable

        template =
          if recordable.is_a?(Page)
            recordable.landing_components.root_components.map do |component|
              SiteEditor::ComponentRenderer.new(component, marketplace: current_marketplace, template: true).render
            end
          elsif recordable.is_a?(LandingComponent)
            SiteEditor::ComponentRenderer.new(recordable, marketplace: current_marketplace, template: true).render
          end

        return render json: { error: "Template record not found" }, status: :not_found if template.nil?

        render json: render_asset(@asset).merge(template: template)
      end

      private

      def set_page
        @page = current_marketplace.pages.v2_pages.find_by(slug: params[:slug])
      end

      def set_asset
        @asset = Asset.kept.find(params[:id])
      end

      def asset_params
        params.require(:asset).permit(:name, :recordable_type, :recordable_id, :is_network, :is_promo_template, tags: [])
      end

      def resolve_recordable
        if asset_params[:recordable_type] == "Page"
          @page || current_marketplace.pages.v2_pages.find_by!(slug: params[:slug])
        else
          current_marketplace.pages.v2_pages.joins(:landing_components)
                           .merge(LandingComponent.kept.where(id: asset_params[:recordable_id]))
                           .first!
                           .landing_components
                           .find(asset_params[:recordable_id])
        end
      end

      def asset_market_place_id
        ActiveModel::Type::Boolean.new.cast(params[:public]) ? nil : current_marketplace.id
      end

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
end
