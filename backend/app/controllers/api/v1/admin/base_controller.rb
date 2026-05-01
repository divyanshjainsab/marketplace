module Api
  module V1
    module Admin
      class BaseController < Api::V1::BaseController
        before_action :require_authenticated_user!
        before_action :set_current_organization!
        before_action :require_admin_console_access!
        before_action :set_current_marketplace!
        after_action :reset_current_marketplace

        protected

        def current_organization
          Current.organization
        end

        def current_marketplace
          Current.marketplace
        end

        def set_current_organization!
          organization = selected_organization
          return if performed?

          if organization.nil?
            render_error("forbidden", status: :forbidden)
            return
          end

          Current.organization = organization
          Current.org_id = organization.id
        end

        def require_admin_console_access!
          return if admin_access.admin_console_access?(current_organization)

          render_error("forbidden", status: :forbidden)
        end

        def require_admin_permission!(*codes)
          normalized_codes = codes.flatten.compact.map(&:to_s).reject(&:blank?).uniq
          return if normalized_codes.empty?
          return if current_authenticated_user&.respond_to?(:super_admin?) && current_authenticated_user.super_admin?
          return if normalized_codes.any? { |code| current_permissions.include?(code) }

          render_error("forbidden", status: :forbidden)
        end

        def current_permissions
          @current_permissions ||= Rbac::Permissions.codes_for(
            user: current_authenticated_user,
            organization: current_organization
          )
        end

        def current_role
          @current_role ||= admin_access.role_for(current_organization)
        end

        def set_current_marketplace!
          marketplace_id = params[:marketplace_id].to_s.presence

          marketplace = if marketplace_id.present?
            Marketplace.kept.find_by(id: marketplace_id, organization_id: current_organization.id)
          else
            TenantCache.fetch(namespace: "marketplace_default", key: "default", organization: current_organization, expires_in: 60) do
              Marketplace.kept.where(organization_id: current_organization.id).order(:name).first
            end
          end

          if marketplace.nil?
            render_error("not_found", status: :not_found, message: "Marketplace not found")
            return
          end

          Current.marketplace = marketplace
          ActsAsTenant.current_tenant = marketplace
        end

        def reset_current_marketplace
          ActsAsTenant.current_tenant = nil
          Current.marketplace = nil
        end

        def available_organizations
          @available_organizations ||= admin_access.admin_console_organizations_scope
        end

        def admin_access
          @admin_access ||= Rbac::Access.new(Current.user)
        end

        def selected_organization
          selected_id = params[:selected_organization_id].presence || request.get_header("HTTP_X_ORGANIZATION").presence

          if selected_id.present?
            return available_organizations.find_by(id: selected_id).tap do |organization|
              render_error("forbidden", status: :forbidden) if organization.nil?
            end
          end

          if Current.organization.present?
            if admin_access.admin_console_access?(Current.organization)
              return Current.organization
            end

            render_error("forbidden", status: :forbidden)
            return nil
          end

          if Current.session_org_id.present?
            organization = available_organizations.find_by(id: Current.session_org_id)
            return organization if organization.present?
          end

          admin_access.default_organization(min_role: :staff, preferred_org_id: Current.session_org_id)
        end
      end
    end
  end
end
