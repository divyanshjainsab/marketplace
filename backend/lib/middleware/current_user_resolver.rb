module Middleware
  class CurrentUserResolver
    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)

      return @app.call(env) if Current.user.present?
      return @app.call(env) unless header_auth_enabled?

      external_id = request.get_header("HTTP_X_SSO_USER_ID").to_s
      external_id = request.get_header("HTTP_X_USER_EXTERNAL_ID").to_s if external_id.empty?

      if external_id.present?
        Current.user = User.kept.find_by(external_id: external_id)
        env["app.current_user"] = Current.user
      end

      @app.call(env)
    end

    private

    def header_auth_enabled?
      ActiveModel::Type::Boolean.new.cast(ENV.fetch("BACKEND_HEADER_AUTH_ENABLED", "false"))
    end
  end
end
