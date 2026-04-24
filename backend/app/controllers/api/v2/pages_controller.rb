module Api
  module V2
    class PagesController < BaseController
      before_action :set_page, only: :show

      def index
        pages = current_marketplace.pages.v2_pages.order(:slug)
        render json: {
          pages: pages.map { |page| page.slice(:id, :name, :slug, :title, :template, :v2) }
        }
      end

      def show
        scoped_components = @page.landing_components.root_components.reorder(row_index: :asc, id: :asc)

        components_page = []
        total_pages = nil
        total_count = nil
        per_page = 5

        if scoped_components.exists?
          page_number = params[:page].to_i
          page_number = 1 if page_number <= 0
          total_count = scoped_components.count
          total_pages = (total_count.to_f / per_page).ceil

          components_page = scoped_components.offset((page_number - 1) * per_page).limit(per_page)
        end

        payload = {
          id: @page.id,
          title: @page.title,
          slug: @page.slug,
          created_at: @page.created_at,
          updated_at: @page.updated_at,
          custom: @page.custom,
          components: components_page.map { |component| SiteEditor::ComponentRenderer.new(component, marketplace: current_marketplace).render }
        }
        if components_page.any?
          payload[:total_pages] = total_pages
          payload[:total_count] = total_count
          payload[:per_page] = per_page
        end

        render json: payload
      end

      private

      def set_page
        @page =
          if can_manage_marketplace?
            current_marketplace.pages.v2_pages.find_or_create_by!(slug: params[:slug])
          else
            current_marketplace.pages.v2_pages.find_by!(slug: params[:slug])
          end
      end
    end
  end
end
