module Api
  module V2
    class PageVersionsController < BaseController
      before_action :require_manager!
      before_action :set_page
      before_action :set_version, only: :restore

      def index
        versions = PageVersioningService.new(@page).versions
        render json: { versions: versions.map(&:summary) }
      end

      def restore
        version = PageVersioningService.new(@page).restore!(version_number: @version.version_number)
        @page.clear_cache
        audit_log!(
          action: "page.restore",
          resource: @page,
          changes: {},
          metadata: {
            market_place_id: current_marketplace.id,
            page_slug: @page.slug,
            version_number: @version.version_number
          }
        )
        render json: {
          message: "Page restored to version #{version.version_number}",
          version: version.summary
        }
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def set_page
        @page = current_marketplace.pages.v2_pages.find_by!(slug: params[:slug])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Page not found" }, status: :not_found
      end

      def set_version
        @version = PageVersion.kept.find_by!(page: @page, version_number: params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Version #{params[:id]} not found" }, status: :not_found
      end
    end
  end
end
