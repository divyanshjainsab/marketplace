module Api
  module V1
    module Admin
      class OrganizationsController < BaseController
        def index
          page = paginate(Organization.kept.order(:name))
          render_collection(page, serializer: OrganizationSerializer)
        end

        def show
          organization = Organization.kept.find(params[:id])
          render_resource(organization, serializer: OrganizationSerializer)
        end
      end
    end
  end
end

