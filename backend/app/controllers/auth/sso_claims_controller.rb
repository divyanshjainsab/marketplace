module Auth
  class SsoClaimsController < ActionController::API
    before_action :authenticate_sso_backend!

    def create
      external_id = params[:external_id].to_s
      org_slug = params[:org_slug].to_s

      return render json: { allowed: false, error: "missing_external_id" }, status: :bad_request if external_id.blank?
      return render json: { allowed: false, error: "missing_org_slug" }, status: :bad_request if org_slug.blank?

      organization = Organization.kept.find_by(slug: org_slug)
      return render json: { allowed: false, error: "unknown_org" }, status: :not_found if organization.nil?

      user = User.kept.find_or_initialize_by(external_id: external_id)
      user.email = params[:email].to_s.presence if params[:email].present?
      user.name = params[:name].to_s.presence if params[:name].present?
      user.save! if user.changed?

      membership = OrganizationMembership.kept.find_by(user_id: user.id, organization_id: organization.id)
      allowed = membership.present? && Rbac::Registry.rank_for(membership.role) >= Rbac::Registry.rank_for("admin")

      roles = ["user"]
      roles << "admin" if allowed

      render json: {
        allowed: allowed,
        org_id: organization.id,
        org_slug: organization.slug,
        roles: roles
      }
    end

    private

    def authenticate_sso_backend!
      expected = ENV.fetch("SSO_BACKEND_SHARED_SECRET", "")
      provided = request.headers["X-SSO-Backend-Secret"].to_s

      head :unauthorized unless expected.present? && ActiveSupport::SecurityUtils.secure_compare(expected, provided)
    end
  end
end

