module Api
  module V1
    module Admin
      class UsersController < BaseController
        before_action do
          require_admin_permission!("view_organization_users")
        end

        def index
          scope = User.kept
            .joins(:organization_memberships)
            .merge(OrganizationMembership.kept.where(organization_id: current_organization.id))
            .distinct
            .order(created_at: :desc)
          page = paginate(scope)
          render_collection(page, serializer: UserSerializer)
        end

        def show
          user = User.kept
            .joins(:organization_memberships)
            .merge(OrganizationMembership.kept.where(organization_id: current_organization.id))
            .distinct
            .find(params[:id])
          render_resource(user, serializer: UserSerializer)
        end
      end
    end
  end
end
