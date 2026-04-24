module Api
  module V1
    module Admin
      class OrganizationsController < BaseController
        before_action do
          require_admin_permission!("manage_organization")
        end

        def index
          render json: {
            data: [OrganizationSerializer.one(current_organization)],
            meta: { page: 1, per_page: 1, total_count: 1, total_pages: 1 }
          }
        end

        def show
          render_resource(current_organization, serializer: OrganizationSerializer)
        end
      end
    end
  end
end
