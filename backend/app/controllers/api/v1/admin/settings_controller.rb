module Api
  module V1
    module Admin
      class SettingsController < BaseController
        before_action only: :show do
          require_admin_permission!("view_market_places")
        end

        before_action only: :update do
          require_admin_permission!("manage_organization", "edit_market_places")
        end

        def show
          render json: {
            data: settings_payload
          }
        end

        def update
          ActiveRecord::Base.transaction do
            current_organization.update_admin_settings!(settings_params.to_h)
            TenantCache.bump_namespace_version!(organization_id: current_organization.id, namespace: "admin_dashboard")
            audit_log!(
              action: "organization.settings.update",
              resource: current_organization,
              changes: current_organization.saved_changes
            )
          end

          render json: {
            data: settings_payload
          }
        end

        private

        def settings_params
          params.require(:settings).permit!
        end

        def settings_payload
          {
            organization: OrganizationSerializer.one(current_organization),
            settings: current_organization.normalized_admin_settings,
            sharing_scope: current_organization.product_sharing_scope
          }
        end
      end
    end
  end
end
