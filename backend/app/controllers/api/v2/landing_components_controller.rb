module Api
  module V2
    class LandingComponentsController < BaseController
      before_action :require_manager!
      before_action :set_page, only: :batch_update
      before_action :set_component, only: :update

      def batch_update
        requested_ids = []
        ActiveRecord::Base.transaction do
          components = normalized_components
          requested_ids = components.map { |component| component["id"] }.compact.map(&:to_i)
          if requested_ids.any?
            @page.landing_components.kept.where.not(id: requested_ids).discard_all
          else
            @page.landing_components.kept.discard_all
          end

          components.each_with_index do |component_params, index|
            requested_row_index = Integer(component_params["row_index"], exception: false)
            SiteEditor::ComponentUpsert.new(
              page: @page,
              component_params: component_params,
              row_index: requested_row_index || index
            ).call
          end
        end

        capture_page_version(@page)
        @page.clear_cache
        audit_log!(
          action: "site_editor.components.batch_update",
          resource: @page,
          changes: {},
          metadata: {
            market_place_id: current_marketplace.id,
            page_slug: @page.slug,
            requested_component_ids: requested_ids
          }
        )
        head :ok
      rescue StandardError => e
        Rails.logger.error("[LandingComponentsController#batch_update] Error: #{e.message}\n#{e.backtrace.join("\n")}")
        render json: { error: e.message }, status: :internal_server_error
      end

      def update
        ActiveRecord::Base.transaction do
          requested_row_index = Integer(single_component_params["row_index"], exception: false)
          component = SiteEditor::ComponentUpsert.new(
            page: @component.page,
            component_params: single_component_params.merge("id" => @component.id),
            row_index: requested_row_index || @component.row_index,
            parent_component: @component.parent_component
          ).call
          component.page.clear_cache
        end

        audit_log!(
          action: "site_editor.component.update",
          resource: @component.page,
          changes: {},
          metadata: {
            market_place_id: current_marketplace.id,
            page_slug: @component.page.slug,
            component_id: @component.id
          }
        )
        head :ok
      rescue StandardError => e
        Rails.logger.error("[LandingComponentsController#update] Error: #{e.message}\n#{e.backtrace.join("\n")}")
        render json: { error: e.message }, status: :internal_server_error
      end

      private

      def set_page
        @page = current_marketplace.pages.v2_pages.find_or_create_by!(slug: params[:slug])
      end

      def set_component
        @component = LandingComponent.joins(:page)
                                     .merge(Page.v2_pages.where(market_place_id: current_marketplace.id))
                                     .find(params[:id])
      end

      def normalized_components
        raw = params[:landing_components]
        return [] if raw.blank?
        return raw.map { |item| normalize_hash(item) } if raw.is_a?(Array)

        normalize_hash(raw).sort_by { |key, _| key.to_i }.map { |(_, value)| normalize_hash(value) }
      end

      def normalize_hash(value)
        case value
        when ActionController::Parameters
          value.to_unsafe_h.transform_values { |child| normalize_hash(child) }
        when Hash
          value.transform_values { |child| normalize_hash(child) }
        when Array
          value.map { |child| normalize_hash(child) }
        else
          value
        end
      end

      def single_component_params
        normalize_hash(params.require(:landing_component))
      end

      def capture_page_version(page)
        PageVersioningService.new(page).capture!(created_by: Current.user&.email)
      rescue StandardError
        nil
      end
    end
  end
end
