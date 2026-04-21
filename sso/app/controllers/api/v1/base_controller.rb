module Api
  module V1
    class BaseController < ActionController::API
      before_action :set_cors_headers
      before_action :authenticate_api_user!

      private

      def authenticate_api_user!
        # Allow same-origin session usage for SSO's own UI (useful for internal fetches).
        if request.authorization.to_s.blank?
          user = session_user_from_cookie
          return set_current_api_user!(user) if user.present?
        end

        token = bearer_token
        verification = ::Oidc::IdTokenVerifier.verify(id_token: token)
        return render json: { error: verification.error || "unauthorized" }, status: :unauthorized unless verification.ok?

        sub = verification.payload["sub"].to_s
        user = User.find_by(external_id: sub)
        return render json: { error: "unknown_user" }, status: :unauthorized if user.nil?

        set_current_api_user!(user)
      end

      def session_user_from_cookie
        # ActionController::API doesn't include Devise helpers.
        warden = request.env["warden"]
        return nil if warden.nil?
        warden.authenticate(scope: :user)
      rescue StandardError
        nil
      end

      def set_current_api_user!(user)
        @current_api_user = user
      end

      def current_api_user
        @current_api_user
      end

      def bearer_token
        header = request.authorization.to_s
        return header.split.last if header.start_with?("Bearer ")
        ""
      end

      def set_cors_headers
        origin = request.headers["Origin"].to_s
        allowed = allowed_origins
        if origin.present? && allowed.include?(origin)
          response.headers["Access-Control-Allow-Origin"] = origin
          response.headers["Vary"] = "Origin"
          response.headers["Access-Control-Allow-Credentials"] = "true"
        end

        response.headers["Access-Control-Allow-Headers"] = "Authorization, Content-Type"
        response.headers["Access-Control-Allow-Methods"] = "GET, POST, PATCH, DELETE, OPTIONS"
        response.headers["Access-Control-Max-Age"] = "600"
      end

      def allowed_origins
        ENV.fetch("SSO_ALLOWED_ORIGINS")
          .split(",")
          .map(&:strip)
          .reject(&:blank?)
      end
    end
  end
end
