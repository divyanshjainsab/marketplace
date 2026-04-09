module Auth
  class TokensController < ApplicationController
    protect_from_forgery with: :null_session

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

    private

    def request_token
      header = request.headers["Authorization"].to_s
      return header.split.last if header.start_with?("Bearer ")

      params[:token].to_s.presence || cookies.encrypted[:sso_jwt].to_s.presence
    end
  end
end
