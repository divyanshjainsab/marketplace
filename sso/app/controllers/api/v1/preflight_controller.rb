module Api
  module V1
    class PreflightController < ActionController::API
      def options
        origin = request.headers["Origin"].to_s
        allowed = ENV.fetch("SSO_ALLOWED_ORIGINS")
          .split(",")
          .map(&:strip)
          .reject(&:blank?)

        if origin.present? && allowed.include?(origin)
          response.headers["Access-Control-Allow-Origin"] = origin
          response.headers["Vary"] = "Origin"
          response.headers["Access-Control-Allow-Credentials"] = "true"
        end

        response.headers["Access-Control-Allow-Headers"] = "Authorization, Content-Type"
        response.headers["Access-Control-Allow-Methods"] = "GET, POST, PATCH, DELETE, OPTIONS"
        response.headers["Access-Control-Max-Age"] = "600"
        head :no_content
      end
    end
  end
end
