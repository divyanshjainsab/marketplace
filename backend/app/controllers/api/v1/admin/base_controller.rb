module Api
  module V1
    module Admin
      class BaseController < Api::V1::BaseController
        before_action :require_authenticated_user!
        before_action :require_admin!
        before_action :set_current_organization!
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
          organization = Current.organization

          if organization.nil?
            org_id = Current.org_id.to_i
            org_id = Current.session_org_id.to_i if org_id <= 0 && Current.session_org_id.present?
            organization = Rails.cache.fetch("org:by_id:#{org_id}", expires_in: 60) do
              Organization.kept.find_by(id: org_id)
            end
          end

          if organization.nil?
            render_error("forbidden", status: :forbidden)
            return
          end

          Current.organization = organization
          Current.org_id = organization.id
        end

        def set_current_marketplace!
          marketplace_id = params[:marketplace_id].to_s.presence

          marketplace = if marketplace_id.present?
            Marketplace.kept.find_by(id: marketplace_id, organization_id: current_organization.id)
          else
            Rails.cache.fetch("marketplace:default_for_org:#{current_organization.id}", expires_in: 60) do
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
      end
    end
  end
end
