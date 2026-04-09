module Auth
  class SessionsController < Devise::SessionsController
    protect_from_forgery with: :exception, unless: -> { request.format.json? }
    before_action :ensure_login_not_rate_limited!, only: :create

    def create
      self.resource = warden.authenticate!(auth_options)
      set_flash_message!(:notice, :signed_in)
      sign_in(resource_name, resource)

      token_pair = Sso::RefreshTokens.issue(user: resource, request: request)

      respond_to do |format|
        format.html do
          cookies.encrypted[:sso_jwt] = {
            value: token_pair.access_token,
            expires: token_pair.access_exp,
            httponly: true,
            secure: Rails.env.production?,
            same_site: :lax
          }
          redirect_to login_redirect_url(token_pair)
        end
        format.json do
          render json: {
            token: token_pair.access_token,
            refresh_token: token_pair.refresh_token,
            exp: token_pair.access_exp.to_i,
            refresh_exp: token_pair.refresh_exp.to_i,
            user: { external_id: resource.external_id, email: resource.email, name: resource.name }
          }
        end
      end
    end

    def destroy
      token = request_token
      revoke_token(token) if token.present?
      revoke_refresh_token(request_refresh_token) if request_refresh_token.present?

      cookies.delete(:sso_jwt)
      sign_out(resource_name)

      respond_to do |format|
        format.html { redirect_to login_path, notice: "Logged out" }
        format.json { head :no_content }
      end
    end

    private

    def request_token
      header = request.headers["Authorization"].to_s
      return header.split.last if header.start_with?("Bearer ")

      cookies.encrypted[:sso_jwt].to_s.presence
    end

    def request_refresh_token
      params[:refresh_token].to_s.presence
    end

    def revoke_token(token)
      decoded = Sso::JwtTokens.decode(token: token)
      jti = decoded.payload["jti"]
      exp = Time.at(decoded.payload["exp"])
      JwtDenylist.create!(jti: jti, exp: exp)
    rescue JWT::DecodeError
      nil
    end

    def revoke_refresh_token(token)
      digest = Digest::SHA256.hexdigest(token)
      RefreshToken.active.find_by(token_digest: digest)&.update!(
        revoked_at: Time.current,
        revoked_reason: "logout",
        last_used_at: Time.current
      )
    end

    def ensure_login_not_rate_limited!
      email = params.dig(resource_name, :email).to_s.downcase
      ip_result = Security::RateLimiter.check(key: "login:ip:#{request.remote_ip}", limit: 20, period: 60)
      email_result = Security::RateLimiter.check(key: "login:email:#{email}", limit: 10, period: 300)
      result = [ip_result, email_result].find { |entry| !entry.allowed? }
      return if result.nil?

      response.set_header("Retry-After", result.retry_after.to_s)
      render json: { error: "rate_limited" }, status: :too_many_requests
    end

    def login_redirect_url(token_pair)
      return after_sign_in_path_for(resource) unless safe_return_to.present?

      uri = URI.parse(safe_return_to)
      params = Rack::Utils.parse_nested_query(uri.query)
      params["token"] = token_pair.access_token
      params["refresh_token"] = token_pair.refresh_token
      params["exp"] = token_pair.access_exp.to_i.to_s
      params["refresh_exp"] = token_pair.refresh_exp.to_i.to_s
      uri.query = params.to_query
      uri.to_s
    rescue URI::InvalidURIError
      after_sign_in_path_for(resource)
    end

    def safe_return_to
      raw = params[:return_to].to_s.presence
      return nil if raw.blank?

      uri = URI.parse(raw)
      return nil unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

      allowed_hosts = ENV.fetch("SSO_ALLOWED_REDIRECT_HOSTS", "localhost:3000").split(",").map(&:strip)
      host_with_port = [uri.host, uri.port].compact.join(":")
      return nil unless allowed_hosts.include?(host_with_port)

      uri.to_s
    rescue URI::InvalidURIError
      nil
    end
  end
end
