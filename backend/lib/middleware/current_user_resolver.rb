module Middleware
  class CurrentUserResolver
    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)

      external_id = request.get_header("HTTP_X_SSO_USER_ID").to_s
      external_id = request.get_header("HTTP_X_USER_EXTERNAL_ID").to_s if external_id.empty?

      if external_id.present?
        Current.user = User.kept.find_by(external_id: external_id)
      end

      @app.call(env)
    end
  end
end
