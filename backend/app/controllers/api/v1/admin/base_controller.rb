module Api
  module V1
    module Admin
      class BaseController < Api::V1::BaseController
        before_action :require_authenticated_user!
        before_action :require_admin!
        before_action :set_current_organization!

        protected

        def current_organization
          Current.organization
        end

        def set_current_organization!
          org_id = Current.org_id.to_i
          organization = Rails.cache.fetch("org:by_id:#{org_id}", expires_in: 60) do
            Organization.kept.find_by(id: org_id)
          end

          if organization.nil?
            render_error("forbidden", status: :forbidden)
            return
          end

          Current.organization = organization
        end
      end
    end
  end
end
