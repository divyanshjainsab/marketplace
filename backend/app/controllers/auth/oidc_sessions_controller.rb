require "uri"

module Auth
  class OidcSessionsController < ActionController::API
    def start
      app = params[:app].to_s
      client_id = client_id_for(app)
      return render json: { error: "unknown_app" }, status: :bad_request if client_id.blank?

      state = SecureRandom.hex(32)
      nonce = SecureRandom.hex(32)
      code_verifier = SecureRandom.urlsafe_base64(64, false)
      code_challenge = ::Auth::Pkce.code_challenge(code_verifier)

      return_to = sanitize_return_to(params[:return_to])
      org_slug = params[:org_slug].to_s.presence

      redirect_uri = callback_url_for(app)

      OidcLoginState.create!(
        state: state,
        nonce: nonce,
        client_id: client_id,
        redirect_uri: redirect_uri,
        code_verifier: code_verifier,
        app: app,
        return_to: return_to,
        org_slug: org_slug,
        expires_at: 10.minutes.from_now,
        ip_address: request.remote_ip,
        user_agent: request.user_agent.to_s.first(500)
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
        code_challenge_method: "S256",
        org_slug: org_slug
      }.compact.to_query

      redirect_to authorize_uri.to_s, allow_other_host: true
    end

    def callback
      app = params[:app].to_s
      code = params[:code].to_s
      state = params[:state].to_s

      return redirect_to frontend_login_url(app: app), allow_other_host: true if code.blank? || state.blank?

      login_state = OidcLoginState.find_by(state: state)
      return redirect_to frontend_login_url(app: app), allow_other_host: true if login_state.nil?
      OidcLoginState.transaction do
        login_state.lock!
        raise ActiveRecord::RecordNotFound if login_state.used_at.present? || login_state.expired?
        raise ActiveRecord::RecordNotFound if login_state.app != app
        login_state.update!(used_at: Time.current)
      end

      exchange = Sso::OidcTokenExchange.call(
        code: code,
        client_id: login_state.client_id,
        client_secret: client_secret_for(login_state.client_id),
        redirect_uri: login_state.redirect_uri,
        code_verifier: login_state.code_verifier
      )
      return redirect_to frontend_login_url(app: app), allow_other_host: true unless exchange.ok?

      verification = Sso::OidcIdTokenVerifier.verify(
        id_token: exchange.id_token,
        client_id: login_state.client_id,
        nonce: login_state.nonce
      )
      return redirect_to frontend_login_url(app: app), allow_other_host: true unless verification.ok?

      claims = verification.payload || {}
      external_id = claims["sub"].to_s
      email = claims["email"].to_s
      name = claims["name"].to_s
      roles = Array(claims["roles"] || [])
      org_id = claims["org_id"]

      return redirect_to frontend_login_url(app: app), allow_other_host: true if external_id.blank?

      if app == "admin"
        return redirect_to frontend_not_authorized_url(app: app), allow_other_host: true unless roles.include?("admin") && org_id.present?
      end

      user = User.kept.find_or_initialize_by(external_id: external_id)
      user.email = email if email.present?
      user.name = name if name.present?
      user.roles = roles if user.respond_to?(:roles=)
      user.save! if user.changed?

      if app == "admin"
        allowed = OrganizationMembership.kept.find_by(user_id: user.id, organization_id: org_id)&.then do |membership|
          Rbac::Registry.rank_for(membership.role) >= Rbac::Registry.rank_for("admin")
        end
        return redirect_to frontend_not_authorized_url(app: app), allow_other_host: true unless allowed
      end

      session_pair = Auth::SessionManager.issue(user: user, org_id: org_id, roles: roles, request: request)
      Auth::SessionCookies.set_access!(response: response, token: session_pair.access_token, expires_at: session_pair.access_exp)
      Auth::SessionCookies.set_refresh!(response: response, token: session_pair.refresh_token, expires_at: session_pair.refresh_exp)

      target = frontend_return_url(app: app, return_to: login_state.return_to)
      redirect_to target, allow_other_host: true
    rescue ActiveRecord::RecordInvalid
      redirect_to frontend_login_url(app: params[:app].to_s), allow_other_host: true
    rescue ActiveRecord::RecordNotFound
      redirect_to frontend_login_url(app: params[:app].to_s), allow_other_host: true
    end

    def refresh
      refresh_token = Auth::SessionCookies.read_from_cookie_header(request.get_header("HTTP_COOKIE"), name: Auth::SessionCookies::REFRESH_COOKIE)
      return render json: { ok: false, error: "missing_refresh_token" }, status: :unauthorized if refresh_token.blank?

      pair = Auth::SessionManager.rotate(refresh_token: refresh_token, request: request)
      Auth::SessionCookies.set_access!(response: response, token: pair.access_token, expires_at: pair.access_exp)
      Auth::SessionCookies.set_refresh!(response: response, token: pair.refresh_token, expires_at: pair.refresh_exp)

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
      render json: { ok: true }
    end

    private

    def sso_public_base_url
      (ENV["SSO_PUBLIC_BASE_URL"].presence || "http://localhost:3002").delete_suffix("/")
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
        ENV.fetch("SSO_OIDC_ADMINFRONT_CLIENT_SECRET", "dev-adminfront-secret")
      when "clientfront"
        ENV.fetch("SSO_OIDC_CLIENTFRONT_CLIENT_SECRET", "dev-clientfront-secret")
      else
        ""
      end
    end

    def backend_public_base_url
      (ENV["BACKEND_PUBLIC_BASE_URL"].presence || "http://localhost:3001").delete_suffix("/")
    end

    def callback_url_for(app)
      "#{backend_public_base_url}/auth/oidc/callback/#{app}"
    end

    def frontend_base_url(app)
      case app.to_s
      when "admin"
        ENV.fetch("ADMINFRONT_BASE_URL", "http://localhost:3004")
      else
        ENV.fetch("CLIENTFRONT_BASE_URL", "http://localhost:3000")
      end
    end

    def frontend_login_url(app:)
      base = frontend_base_url(app)
      uri = URI.parse(base)
      uri.path = "/login"
      uri.query = nil
      uri.to_s
    rescue URI::InvalidURIError
      "/"
    end

    def frontend_not_authorized_url(app:)
      base = frontend_base_url(app)
      uri = URI.parse(base)
      uri.path = "/not-authorized"
      uri.query = nil
      uri.to_s
    rescue URI::InvalidURIError
      "/"
    end

    def frontend_return_url(app:, return_to:)
      base = frontend_base_url(app)
      path = return_to.to_s.presence || (app.to_s == "admin" ? "/dashboard" : "/")
      parsed = URI.parse(path)
      if parsed.is_a?(URI::Generic) && parsed.scheme.nil? && parsed.host.nil?
        path_only = parsed.path.presence || "/"
        query = parsed.query
      else
        path_only = "/"
        query = nil
      end
      uri = URI.parse(base)
      uri.path = path_only
      uri.query = query
      uri.to_s
    rescue URI::InvalidURIError
      "/"
    end

    def sanitize_return_to(raw)
      value = raw.to_s.strip
      return nil if value.blank?
      return nil unless value.start_with?("/")
      return nil if value.start_with?("//")
      value
    end
  end
end
