require "uri"

module Auth
  class OidcSessionsController < ActionController::API
    before_action :require_frontend_proxy!, only: %i[refresh logout]

    def start
      app = params[:app].to_s
      client_id = client_id_for(app)
      return render json: { error: "unknown_app" }, status: :bad_request if client_id.blank?

      nonce = SecureRandom.hex(32)
      code_verifier = SecureRandom.urlsafe_base64(64, false)
      code_challenge = ::Auth::Pkce.code_challenge(code_verifier)

      return_to = sanitize_return_to(params[:return_to])
      origin = normalize_origin(
        host: params[:origin_host],
        port: params[:origin_port],
        scheme: params[:origin_scheme]
      )
      return render json: { error: "invalid_origin" }, status: :bad_request unless origin_allowed_for_app?(origin: origin, app: app)

      redirect_uri = callback_url_for(app)
      state = ::Auth::OidcState.issue(
        {
          "app" => app,
          "client_id" => client_id,
          "redirect_uri" => redirect_uri,
          "code_verifier" => code_verifier,
          "nonce" => nonce,
          "return_to" => return_to,
          "origin_host" => origin[:host],
          "origin_port" => origin[:port],
          "origin_scheme" => origin[:scheme]
        }
      )

      authorize_uri = URI.join(sso_public_base_url + "/", "authorize")
      authorize_uri.query = {
        client_id: client_id,
        redirect_uri: redirect_uri,
        response_type: "code",
        scope: "openid profile",
        state: state,
        nonce: nonce,
        code_challenge: code_challenge,
        code_challenge_method: "S256"
      }.compact.to_query

      redirect_to authorize_uri.to_s, allow_other_host: true
    end

    def callback
      app = params[:app].to_s
      error = params[:error].to_s
      error_description = params[:error_description].to_s
      code = params[:code].to_s
      state = params[:state].to_s
      payload = verify_state_payload(state)
      frontend_origin = origin_from_payload(payload, app: app)

      if error.present?
        if app == "admin"
          return redirect_to frontend_not_authorized_url(app: app, origin: frontend_origin), allow_other_host: true
        end

        uri = URI.parse(frontend_login_url(app: app, origin: frontend_origin))
        uri.query = { error: error, error_description: error_description.presence }.compact.to_query
        return redirect_to uri.to_s, allow_other_host: true
      end

      return redirect_to frontend_login_url(app: app, origin: frontend_origin), allow_other_host: true if code.blank? || state.blank?
      return redirect_to frontend_login_url(app: app, origin: frontend_origin), allow_other_host: true if payload.nil? || payload["app"].to_s != app

      exchange = Sso::OidcTokenExchange.call(
        code: code,
        client_id: payload.fetch("client_id"),
        client_secret: client_secret_for(payload.fetch("client_id")),
        redirect_uri: payload.fetch("redirect_uri"),
        code_verifier: payload.fetch("code_verifier")
      )
      return redirect_to frontend_login_url(app: app, origin: frontend_origin), allow_other_host: true unless exchange.ok?

      verification = Sso::OidcIdTokenVerifier.verify(
        id_token: exchange.id_token,
        client_id: payload.fetch("client_id"),
        nonce: payload.fetch("nonce")
      )
      return redirect_to frontend_login_url(app: app, origin: frontend_origin), allow_other_host: true unless verification.ok?

      claims = verification.payload || {}
      external_id = claims["sub"].to_s
      email = claims["email"].to_s
      name = claims["name"].to_s
      roles = Array(claims["roles"] || [])

      return redirect_to frontend_login_url(app: app, origin: frontend_origin), allow_other_host: true if external_id.blank?

      resolved_org = resolve_tenant_from_state(payload)

      user = User.kept.find_or_initialize_by(external_id: external_id)
      user.email = email if email.present?
      user.name = name if name.present?
      if user.respond_to?(:roles)
        claimed_super_admin = roles.include?("super_admin")
        user.roles = Array(user.roles) | (claimed_super_admin ? ["super_admin"] : [])
      end
      user.save! if user.changed?

      login_context = authorize_login!(app: app, user: user, organization: resolved_org, claimed_roles: roles)
      return redirect_to frontend_not_authorized_url(app: app, origin: frontend_origin), allow_other_host: true if login_context.nil?

      session_pair = Auth::SessionManager.issue(
        user: user,
        org_id: login_context[:organization]&.id,
        roles: login_context[:roles],
        request: request
      )

      Auth::SessionCookies.set_access!(response: response, token: session_pair.access_token, expires_at: session_pair.access_exp)
      Auth::SessionCookies.set_refresh!(response: response, token: session_pair.refresh_token, expires_at: session_pair.refresh_exp)
      response.headers["Cache-Control"] = "no-store"

      target = frontend_success_url(app: app, origin: frontend_origin, return_to: payload["return_to"])
      redirect_to target, allow_other_host: true
    rescue ActiveSupport::MessageVerifier::InvalidSignature, KeyError
      redirect_to frontend_login_url(app: params[:app].to_s, origin: frontend_origin), allow_other_host: true
    end

    def refresh
      refresh_token = Auth::SessionCookies.read_from_cookie_header(request.get_header("HTTP_COOKIE"), name: Auth::SessionCookies::REFRESH_COOKIE)
      return render json: { ok: false, error: "missing_refresh_token" }, status: :unauthorized if refresh_token.blank?

      pair = Auth::SessionManager.rotate(refresh_token: refresh_token, request: request)
      Auth::SessionCookies.set_access!(response: response, token: pair.access_token, expires_at: pair.access_exp)
      Auth::SessionCookies.set_refresh!(response: response, token: pair.refresh_token, expires_at: pair.refresh_exp)
      response.headers["Cache-Control"] = "no-store"

      render json: {
        ok: true,
        access_token: pair.access_token,
        exp: pair.access_exp.to_i,
        refresh_token: pair.refresh_token,
        refresh_exp: pair.refresh_exp.to_i
      }
    rescue ActiveRecord::RecordNotFound
      render json: { ok: false, error: "invalid_refresh_token" }, status: :unauthorized
    end

    def logout
      refresh_token = Auth::SessionCookies.read_from_cookie_header(request.get_header("HTTP_COOKIE"), name: Auth::SessionCookies::REFRESH_COOKIE)
      if refresh_token.present?
        digest = UserSession.digest(refresh_token)
        UserSession.active.find_by(refresh_token_digest: digest)&.revoke!(reason: "logout")
      end

      Auth::SessionCookies.clear!(response: response)
      response.headers["Cache-Control"] = "no-store"
      render json: { ok: true }
    end

    private

    def sso_public_base_url
      ENV.fetch("SSO_PUBLIC_BASE_URL").delete_suffix("/")
    end

    def client_id_for(app)
      case app.to_s
      when "admin" then "adminfront"
      when "clientfront", "client" then "clientfront"
      else
        ""
      end
    end

    def client_secret_for(client_id)
      case client_id.to_s
      when "adminfront"
        ENV.fetch("SSO_OIDC_ADMINFRONT_CLIENT_SECRET")
      when "clientfront"
        ENV.fetch("SSO_OIDC_CLIENTFRONT_CLIENT_SECRET")
      else
        ""
      end
    end

    def backend_public_base_url
      ENV.fetch("BACKEND_PUBLIC_BASE_URL").delete_suffix("/")
    end

    def callback_url_for(app)
      "#{backend_public_base_url}/auth/oidc/callback/#{app}"
    end

    def frontend_base_url(app)
      case app.to_s
      when "admin"
        ENV.fetch("ADMINFRONT_BASE_URL")
      else
        ENV.fetch("CLIENTFRONT_BASE_URL")
      end
    end

    def frontend_login_url(app:, origin: nil)
      frontend_url(app: app, origin: origin, path: "/login")
    end

    def frontend_not_authorized_url(app:, origin: nil)
      frontend_url(app: app, origin: origin, path: "/not-authorized")
    end

    def frontend_success_url(app:, origin:, return_to:)
      frontend_url(
        app: app,
        origin: origin,
        path: sanitize_return_to(return_to) || (app == "admin" ? "/dashboard" : "/")
      )
    end

    def sanitize_return_to(raw)
      value = raw.to_s.strip
      return nil if value.blank?
      return nil unless value.start_with?("/")
      return nil if value.start_with?("//")
      value
    end

    def normalize_origin(host:, port:, scheme:)
      uri = URI.parse("#{scheme.presence || "http"}://#{host}:#{port}")
      return nil unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

      normalized_host = uri.host.to_s.downcase
      normalized_host = "localhost" if normalized_host == "127.0.0.1"
      normalized_host = "localhost" if normalized_host == "0.0.0.0"

      normalized_scheme = uri.scheme.to_s.downcase
      normalized_port = uri.port.to_i
      return nil unless normalized_port.positive?

      { scheme: normalized_scheme, host: normalized_host, port: normalized_port }
    rescue URI::InvalidURIError
      nil
    end

    def origin_allowed_for_app?(origin:, app:)
      return false if origin.nil?

      domain = TenantDomain.normalize(host: origin[:host], port: origin[:port], scheme: origin[:scheme])
      return false if domain.blank?

      if app.to_s == "admin"
        frontend = URI.parse(frontend_base_url(app))
        configured = TenantDomain.normalize(host: frontend.host, port: frontend.port, scheme: frontend.scheme)
        return domain == configured
      end

      Marketplace.kept.exists?(custom_domain: domain)
    rescue URI::InvalidURIError
      false
    end

    def origin_from_payload(payload, app:)
      return nil unless payload.is_a?(Hash)

      origin = normalize_origin(
        host: payload["origin_host"],
        port: payload["origin_port"],
        scheme: payload["origin_scheme"]
      )
      return nil unless origin_allowed_for_app?(origin: origin, app: app)

      origin
    end

    def verify_state_payload(state)
      return nil if state.blank?

      ::Auth::OidcState.verify(state)
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      nil
    end

    def resolve_tenant_from_state(payload)
      return nil unless payload.is_a?(Hash)

      domain = TenantDomain.normalize(host: payload["origin_host"], port: payload["origin_port"], scheme: payload["origin_scheme"])
      return nil if domain.blank?

      Marketplace.kept.includes(:organization).find_by(custom_domain: domain)&.organization
    end

    def authorize_login!(app:, user:, organization:, claimed_roles:)
      claimed_roles = Array(claimed_roles || [])
      super_admin = claimed_roles.include?("super_admin") || (user.respond_to?(:super_admin?) && user.super_admin?)
      access = Rbac::Access.new(user)

      return {
        roles: ["super_admin"],
        organization: organization || access.default_organization(min_role: :staff)
      } if super_admin

      return {
        roles: ["user"],
        organization: organization
      } if app != "admin"

      chosen_organization =
        if organization.present? && access.admin_console_access?(organization)
          organization
        else
          access.default_organization(min_role: :staff, preferred_org_id: organization&.id)
        end
      return nil if chosen_organization.nil?

      membership_role = access.role_for(chosen_organization)
      return nil if membership_role.blank?
      return nil unless access.admin_console_access?(chosen_organization)

      {
        roles: [membership_role],
        organization: chosen_organization
      }
    end

    def frontend_url(app:, path:, origin: nil, query: nil)
      uri = frontend_origin_uri(app: app, origin: origin)
      uri.path = path
      uri.query = query&.to_query
      uri.to_s
    rescue URI::InvalidURIError
      "/"
    end

    def frontend_origin_uri(app:, origin: nil)
      if origin_allowed_for_app?(origin: origin, app: app)
        scheme = origin[:scheme].to_s.presence || "http"
        host = origin[:host].to_s
        port = origin[:port].to_i
        base = +"#{scheme}://#{host}"
        base << ":#{port}" if port.positive? && (localhost?(host) || non_default_port?(scheme, port))
        return URI.parse(base)
      end

      URI.parse(frontend_base_url(app))
    end

    def localhost?(host)
      %w[localhost 127.0.0.1 0.0.0.0].include?(host.to_s.downcase)
    end

    def non_default_port?(scheme, port)
      !(scheme == "http" && port == 80) && !(scheme == "https" && port == 443)
    end

    def require_frontend_proxy!
      return if request.get_header("HTTP_X_FRONTEND_PROXY").to_s == "1"

      render json: { ok: false, error: "forbidden_origin" }, status: :forbidden
    end
  end
end
