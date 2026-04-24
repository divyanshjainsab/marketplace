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
        user = Current.user
        organization = effective_organization(user)
        marketplace = effective_marketplace(organization)
        permissions = organization.present? ? Rbac::Permissions.codes_for(user: user, organization: organization) : []
        current_role = organization.present? && user.present? ? Rbac::Access.new(user).role_for(organization) : nil

        {
          authenticated: user.present?,
          admin_authorized: admin_authorized?(user, organization),
          admin_console_access: admin_console_access?(user, organization),
          tenant_resolved: organization.present?,
          user: user ? UserSerializer.one(user, context: { organization: organization, permissions: permissions, current_role: current_role }) : nil,
          marketplace: marketplace ? MarketplaceSerializer.one(marketplace) : nil,
          organization: organization ? OrganizationSerializer.one(organization) : nil
        }
      end

      def admin_authorized?(user, organization)
        return false if user.blank? || organization.blank?
        return true if user.respond_to?(:super_admin?) && user.super_admin?

        Rbac::Access.new(user).admin_console_access?(organization)
      end

      def admin_console_access?(user, organization)
        return false if user.blank?

        access = Rbac::Access.new(user)
        return true if organization.present? && access.admin_console_access?(organization)

        access.admin_console_access?
      end

      def effective_organization(user)
        return nil if user.blank?

        access = Rbac::Access.new(user)
        selected_id = params[:selected_organization_id].presence

        if selected_id.present?
          selected = access.admin_console_organizations_scope.find_by(id: selected_id)
          return selected if selected.present?
        end

        return Current.organization if Current.organization.present? && Current.marketplace.present?

        if Current.organization.present? && access.admin_console_access?(Current.organization)
          return Current.organization
        end

        if Current.session_org_id.present?
          session_org = access.admin_console_organizations_scope.find_by(id: Current.session_org_id)
          return session_org if session_org.present?
        end

        Current.organization || access.default_organization(min_role: :staff, preferred_org_id: Current.session_org_id)
      end

      def effective_marketplace(organization)
        return Current.marketplace if Current.marketplace.present? && organization.present? && Current.marketplace.organization_id == organization.id
        return nil if organization.blank?

        Marketplace.kept.where(organization_id: organization.id).order(:name, :id).first
      end
    end
  end
end
