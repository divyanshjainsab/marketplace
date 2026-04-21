class ApplicationController < ActionController::API
  include PaperTrail::Rails::Controller
  include Pundit::Authorization

  before_action :restore_current_context
  before_action :verify_frontend_proxy_for_unsafe_requests
  before_action :set_current_tenant
  before_action :set_paper_trail_whodunnit
  after_action :reset_current_tenant

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
  rescue_from ActionController::ParameterMissing, with: :render_parameter_missing
  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden

  private

  def restore_current_context
    Current.marketplace = request.get_header("app.current_marketplace")
    Current.user = request.get_header("app.current_user")
    Current.request_host = request.get_header("app.request_host")
    Current.org_id = request.get_header("app.current_org_id")
    Current.organization = request.get_header("app.current_organization")
    Current.session_org_id = request.get_header("app.session_org_id")
    Current.session_roles = request.get_header("app.session_roles")
  end

  def set_current_tenant
    return if request.path.start_with?("/api/v1/admin") || request.path.start_with?("/auth/oidc/") || request.path.start_with?("/auth/session")

    ActsAsTenant.current_tenant = current_marketplace
  end

  def reset_current_tenant
    ActsAsTenant.current_tenant = nil
  end

  def pundit_user
    current_authenticated_user
  end

  def user_for_paper_trail
    current_authenticated_user&.external_id
  end

  def require_authenticated_user!
    return if Current.user.present?

    render_error("unauthorized", status: :unauthorized)
  end

  def require_admin!
    user = Current.user
    return render_error("forbidden", status: :forbidden) if user.blank?
    return if user.respond_to?(:super_admin?) && user.super_admin?

    org_id = (Current.organization&.id || Current.org_id || Current.session_org_id).to_i
    return render_error("forbidden", status: :forbidden) if org_id <= 0

    allowed = Rails.cache.fetch("rbac:org_admin:#{user.id}:#{org_id}", expires_in: 60) do
      membership = OrganizationMembership.kept.find_by(user_id: user.id, organization_id: org_id)
      membership.present? && Rbac::Registry.rank_for(membership.role) >= Rbac::Registry.rank_for("admin")
    end

    return if allowed

    render_error("forbidden", status: :forbidden)
  end

  def paginate(scope)
    @pagination = Pagination::Relation.new(scope, page: params[:page], per_page: params[:per_page])
    @pagination.call
  end

  def per_page_limit
    Pagination::Relation.per_page_value(params[:per_page])
  end

  def render_resource(resource, serializer:, status: :ok, context: {})
    render json: {
      data: serializer.one(resource, context: context),
      meta: pagination_meta
    }, status: status
  end

  def render_collection(collection, serializer:, context: {})
    render json: {
      data: serializer.many(collection, context: context),
      meta: pagination_meta
    }
  end

  def render_error(code, status:, message: nil, details: nil)
    render json: {
      error: {
        code: code,
        message: message || code.to_s.humanize,
        details: details
      }
    }, status: status
  end

  def pagination_meta
    return {} unless defined?(@pagination) && @pagination

    @pagination.meta
  end

  def render_not_found(error)
    render_error("not_found", status: :not_found, message: error.message)
  end

  def render_record_invalid(error)
    render_error("validation_failed", status: :unprocessable_entity, message: error.record.errors.full_messages.to_sentence, details: error.record.errors.to_hash(true))
  end

  def render_parameter_missing(error)
    render_error("bad_request", status: :bad_request, message: error.message)
  end

  def render_forbidden(error)
    Rails.logger.warn(
      {
        event: "pundit_forbidden",
        policy: error.policy.class.name,
        query: error.query
      }.to_json
    )
    render_error("forbidden", status: :forbidden)
  end

  def current_marketplace
    Current.marketplace
  end

  def current_authenticated_user
    Current.user
  end

  def verify_frontend_proxy_for_unsafe_requests
    return if request.get? || request.head? || request.options?
    return unless cookie_backed_session_request?
    return if request.get_header("HTTP_X_FRONTEND_PROXY").to_s == "1"

    render_error("csrf_failed", status: :forbidden, message: "Request origin not allowed")
  end

  def cookie_backed_session_request?
    cookie_header = request.get_header("HTTP_COOKIE").to_s
    Auth::SessionCookies.read_from_cookie_header(cookie_header, name: Auth::SessionCookies::ACCESS_COOKIE).present? ||
      Auth::SessionCookies.read_from_cookie_header(cookie_header, name: Auth::SessionCookies::REFRESH_COOKIE).present?
  end
end
