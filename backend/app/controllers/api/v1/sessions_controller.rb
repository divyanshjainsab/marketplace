module Api
  module V1
    class SessionsController < BaseController
      def show
        render json: {
          data: session_payload
        }
      end

      private

      def session_payload
        organization = Current.organization
        user = Current.user

        {
          authenticated: user.present?,
          admin_authorized: admin_authorized?(user, organization),
          tenant_resolved: organization.present?,
          user: user ? UserSerializer.one(user) : nil,
          marketplace: Current.marketplace ? MarketplaceSerializer.one(Current.marketplace) : nil,
          organization: organization ? OrganizationSerializer.one(organization) : nil
        }
      end

      def admin_authorized?(user, organization)
        return false if user.blank? || organization.blank?
        return true if user.respond_to?(:super_admin?) && user.super_admin?

        Rbac::Access.new(user).at_least?(resource: organization, role: :admin)
      end
    end
  end
end
