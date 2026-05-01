class ApplicationController < ActionController::API
  include PaperTrail::Rails::Controller
  include Pundit::Authorization

  before_action :initialize_audit_enforcement
  before_action :restore_current_context
  before_action :resolve_current_marketplace!
  before_action :verify_frontend_proxy_for_unsafe_requests
  before_action :set_current_tenant
  before_action :set_paper_trail_whodunnit
  after_action :verify_audit_enforcement
  after_action :reset_current_tenant
  after_action :reset_current_context

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
  rescue_from ActionController::ParameterMissing, with: :render_parameter_missing
  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden
  rescue_from Images::ImageUploader::InvalidUploadError, with: :render_media_validation_failed
  rescue_from Images::AssetPayload::InvalidAssetError, with: :render_media_validation_failed

  private

  def restore_current_context
    Current.user = request.get_header("app.current_user")
    Current.session_org_id = request.get_header("app.session_org_id")
    Current.session_roles = request.get_header("app.session_roles")
    Current.request_id = request.request_id
    Current.remote_ip = request.remote_ip
    Current.user_agent = request.user_agent.to_s.first(500)
  end

  def resolve_current_marketplace!
    return if tenant_resolution_skipped?

    domain = TenantDomain.from_request(request)
    marketplace = Marketplace.kept.includes(:organization).find_by(custom_domain: domain)

    if marketplace.nil?
      response.headers["Cache-Control"] = "no-store"
      render json: { error: "unknown_tenant" }, status: :not_found
      return
    end

    Current.request_host = domain
    Current.marketplace = marketplace
    Current.organization = marketplace.organization
    Current.org_id = marketplace.organization_id

    enforce_session_org_match!
  end

  def tenant_resolution_skipped?
    path = request.path.to_s

    path == "/up" ||
      path.start_with?("/auth/oidc/") ||
      path.start_with?("/auth/session") ||
      path.start_with?("/api/v1/admin") ||
      path == "/api/v1/session" ||
      path == "/api/v1/me" ||
      path == "/api/v1/products/suggestions"
  end

  def enforce_session_org_match!
    return if request.path.start_with?("/api/v1/admin")

    user = Current.user
    return if user.blank?
    return if user.respond_to?(:super_admin?) && user.super_admin?

    tenant_org_id = Current.organization&.id
    session_org_id = Current.session_org_id
    return if tenant_org_id.blank? || session_org_id.blank?

    return if tenant_org_id.to_i == session_org_id.to_i

    render_error("unauthorized", status: :unauthorized, message: "Session org mismatch")
  end

  def set_current_tenant
    return if request.path.start_with?("/api/v1/admin") || request.path.start_with?("/auth/oidc/") || request.path.start_with?("/auth/session")

    ActsAsTenant.current_tenant = current_marketplace
  end

  def reset_current_tenant
    ActsAsTenant.current_tenant = nil
  end

  def reset_current_context
    Current.reset
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

    allowed = TenantCache.fetch(namespace: "rbac", key: "org_admin:user:#{user.id}", organization_id: org_id, expires_in: 60) do
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

  def render_media_validation_failed(error)
    render_error("validation_failed", status: :unprocessable_entity, message: error.message)
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

  def initialize_audit_enforcement
    @audit_logged = false
  end

  def verify_audit_enforcement
    return unless audit_enforcement_required?
    return unless response.status.to_i < 400
    return if @audit_logged

    Rails.logger.error(
      {
        event: "audit.missing",
        request_id: request.request_id,
        method: request.request_method,
        path: request.path,
        organization_id: Current.organization&.id,
        user_id: Current.user&.id
      }.to_json
    )

    raise AuditLogger::MissingContextError, "Audit log missing for #{request.request_method} #{request.path}"
  end

  def audit_enforcement_required?
    return false if request.get? || request.head? || request.options?

    path = request.path.to_s
    path.start_with?("/api/v1/admin") ||
      path.start_with?("/api/v2/") ||
      path == "/api/market_places" ||
      path == "/api/market_place_options" ||
      path.start_with?("/api/assets")
  end

  def audit_log!(action:, resource:, changes: nil, metadata: nil, organization: nil, user: nil)
    @audit_logged = true
    org = organization || Current.organization || Current.marketplace&.organization
    actor = user || Current.user
    AuditLogger.log(user: actor, org: org, action: action, resource: resource, changes: changes, metadata: metadata)
  end
end
