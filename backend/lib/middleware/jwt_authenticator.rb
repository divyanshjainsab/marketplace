module Middleware
  class JwtAuthenticator
    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)

      return @app.call(env) if request.path == "/up"
      return @app.call(env) if request.path.start_with?("/auth/oidc/start/")
      return @app.call(env) if request.path.start_with?("/auth/oidc/callback/")
      return @app.call(env) if request.path == "/auth/session/refresh"
      return @app.call(env) if request.path == "/auth/session" || request.path == "/auth/session/logout"
      return @app.call(env) if request.options?

      token = session_token(request)

      if token.blank?
        return unauthorized("missing_token") if auth_required?(request)
        return @app.call(env)
      end

      decoded = Auth::SessionTokens.decode(token: token)
      payload = decoded.payload

      session_id = payload["sid"].to_i
      if session_id <= 0
        return unauthorized("invalid_session")
      end

      session_record = TenantCache.fetch(
        namespace: "auth_session",
        key: "sid:#{session_id}",
        organization_id: payload["org_id"],
        expires_in: 5
      ) do
        UserSession.active.find_by(id: session_id)
      end
      return unauthorized("session_revoked") if session_record.nil?

      user = User.kept.find_by(id: payload["user_id"])
      return unauthorized("unknown_user") if user.nil?

      Current.user = user
      Current.session_org_id = payload["org_id"]
      Current.session_roles = Array(payload["roles"] || [])
      if !request.path.start_with?("/api/v1/admin") &&
         Current.organization.present? &&
         Current.session_org_id.present? &&
         !user.super_admin? &&
         Current.session_org_id.to_i != Current.organization.id
        return unauthorized("session_org_mismatch")
      end
      env["app.current_user"] = Current.user
      env["app.session_org_id"] = Current.session_org_id
      env["app.session_roles"] = Current.session_roles
      @app.call(env)
    rescue JWT::ExpiredSignature
      unauthorized("expired")
    rescue JWT::DecodeError
      unauthorized("invalid_token")
    ensure
      # Current is reset at the end of the request, but keep this safe even if
      # ordering changes.
      Current.user = nil
      Current.session_org_id = nil
      Current.session_roles = nil
    end

    private

    def session_token(request)
      header = request.get_header("HTTP_AUTHORIZATION").to_s
      if header.start_with?("Bearer ")
        return header.split.last
      end

      cookie_header = request.get_header("HTTP_COOKIE").to_s
      Auth::SessionCookies.read_from_cookie_header(cookie_header, name: Auth::SessionCookies::ACCESS_COOKIE)
    end

    def auth_required?(request)
      return false if public_endpoint?(request)

      ActiveModel::Type::Boolean.new.cast(ENV.fetch("BACKEND_AUTH_REQUIRED"))
    end

    def public_endpoint?(request)
      path = request.path.to_s

      return true if path == "/api/cart" || path == "/api/v1/cart"
      return true if path == "/api/cart/items" || path.start_with?("/api/cart/items/")
      return true if path == "/api/v1/cart_items" || path.start_with?("/api/v1/cart_items/")

      return false unless request.get?

      path.match?(%r{\A/api/v1/listings(?:/\d+)?\z}) ||
        path == "/api/listings" ||
        path == "/listings" ||
        path == "/api/v1/session" ||
        path == "/api/v1/me" ||
        path == "/api/v1/homepage"
    end

    def unauthorized(code)
      body = { error: { code: code, message: code.to_s.humanize } }.to_json
      headers = {
        "Content-Type" => "application/json",
        "Cache-Control" => "no-store"
      }
      [401, headers, [body]]
    end
  end
end
