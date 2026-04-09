module Auth
  class TokensController < ApplicationController
    protect_from_forgery with: :null_session
    before_action :ensure_token_endpoint_not_rate_limited!

    def validate
      token = request_token
      return render json: { valid: false, error: "missing_token" }, status: :unauthorized if token.blank?

      decoded = Sso::JwtTokens.decode(token: token)
      payload = decoded.payload

      if JwtDenylist.active.exists?(jti: payload["jti"])
        return render json: { valid: false, error: "revoked" }, status: :unauthorized
      end

      user = User.find_by!(external_id: payload["sub"])

      render json: {
        valid: true,
        exp: payload["exp"],
        iss: payload["iss"],
        user: { external_id: user.external_id, email: user.email, name: user.name }
      }
    rescue JWT::ExpiredSignature
      render json: { valid: false, error: "expired" }, status: :unauthorized
    rescue JWT::DecodeError
      render json: { valid: false, error: "invalid" }, status: :unauthorized
    rescue ActiveRecord::RecordNotFound
      render json: { valid: false, error: "unknown_user" }, status: :unauthorized
    end

    def refresh
      refresh_token = params[:refresh_token].to_s.presence
      return render json: { error: "missing_refresh_token" }, status: :bad_request if refresh_token.blank?

      rotation = Sso::RefreshTokens.rotate(token: refresh_token, request: request)

      render json: {
        token: rotation.token_pair.access_token,
        refresh_token: rotation.token_pair.refresh_token,
        exp: rotation.token_pair.access_exp.to_i,
        refresh_exp: rotation.token_pair.refresh_exp.to_i,
        user: {
          external_id: rotation.user.external_id,
          email: rotation.user.email,
          name: rotation.user.name
        }
      }
    rescue ActiveRecord::RecordNotFound
      render json: { error: "invalid_refresh_token" }, status: :unauthorized
    end

    private

    def request_token
      header = request.headers["Authorization"].to_s
      return header.split.last if header.start_with?("Bearer ")

      params[:token].to_s.presence || cookies.encrypted[:sso_jwt].to_s.presence
    end

    def ensure_token_endpoint_not_rate_limited!
      result = Security::RateLimiter.check(key: "token:ip:#{request.remote_ip}", limit: 60, period: 60)
      return if result.allowed?

      response.set_header("Retry-After", result.retry_after.to_s)
      render json: { error: "rate_limited" }, status: :too_many_requests
    end
  end
end
