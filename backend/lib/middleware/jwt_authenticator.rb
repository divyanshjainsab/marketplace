module Middleware
  class JwtAuthenticator
    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)

      return @app.call(env) if request.path == "/up"
      return @app.call(env) if request.options?

      token = bearer_token(request)

      if token.blank?
        return unauthorized("missing_token") if auth_required?(request)
        return @app.call(env)
      end

      validation = Sso::TokenValidator.call(token: token)
      return unauthorized(validation.error || "invalid") unless validation.valid

      Current.user = resolve_user(validation)
      env["app.current_user"] = Current.user
      @app.call(env)
    ensure
      # Current is also reset by MarketplaceResolver, but keep this safe even
      # if middleware ordering changes.
      Current.user = nil
    end

    private

    def resolve_user(validation)
      external_id = validation.external_id.to_s
      return nil if external_id.blank?

      user = User.kept.find_or_initialize_by(external_id: external_id)
      user.email = validation.email if validation.email.present?
      user.name = validation.name if validation.name.present?
      user.save! if user.changed?
      user
    end

    def bearer_token(request)
      header = request.get_header("HTTP_AUTHORIZATION").to_s
      return nil unless header.start_with?("Bearer ")

      header.split.last
    end

    def auth_required?(request)
      return false if public_endpoint?(request)

      ActiveModel::Type::Boolean.new.cast(ENV.fetch("BACKEND_AUTH_REQUIRED", "true"))
    end

    def public_endpoint?(request)
      return false unless request.get?

      request.path.match?(%r{\A/api/v1/(product_types|categories|products|variants|listings)(/\d+)?\z}) ||
        request.path == "/api/v1/products/suggestions" ||
        request.path == "/api/v1/session"
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
