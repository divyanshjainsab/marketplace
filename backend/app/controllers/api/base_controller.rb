module Api
  class BaseController < Api::V1::BaseController
    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

    before_action :set_current_marketplace

    private

    def set_current_marketplace
      return if Current.marketplace.present?

      render json: { error: "Marketplace not found" }, status: :not_found
    end

    def current_marketplace
      Current.marketplace
    end

    def record_not_found(exception)
      message =
        if exception.respond_to?(:model) && exception.model.present?
          "#{exception.model} not found"
        else
          exception.message
        end

      render json: { error: message }, status: :not_found
    end

    def can_manage_marketplace?
      user = Current.user
      organization = Current.organization || current_marketplace&.organization
      return false if user.blank? || organization.blank?
      return true if user.respond_to?(:super_admin?) && user.super_admin?

      Rbac::Permissions.codes_for(user: user, organization: organization).include?("manage_marketplace")
    end

    def require_manager!
      return if can_manage_marketplace?

      render json: { error: "Unauthorized" }, status: :unauthorized
    end

    def require_user!
      return if Current.user.present?

      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
end
