module Middleware
  class MarketplaceResolver
    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)

      if request.path == "/up"
        return @app.call(env)
      end
      if request.path.start_with?("/auth/oidc/")
        return @app.call(env)
      end
      if request.path.start_with?("/auth/session")
        return @app.call(env)
      end
      if request.path == "/auth/sso/claims"
        return @app.call(env)
      end
      if request.path.start_with?("/api/v1/admin")
        return @app.call(env)
      end

      Current.request_host = request.host.to_s.downcase
      Current.marketplace = resolve_marketplace(request)
      env["app.current_marketplace"] = Current.marketplace
      env["app.request_host"] = Current.request_host

      if tenant_required? && Current.marketplace.nil?
        return unknown_tenant
      end

      @app.call(env)
    ensure
      Current.reset
    end

    private

    def resolve_marketplace(request)
      host = request.host.to_s.downcase
      override = override_subdomain_for(request)
      override = ENV["DEFAULT_MARKETPLACE_SUBDOMAIN"].to_s.downcase if override.empty?

      if override.present?
        return Marketplace.kept.find_by(subdomain: override)
      end

      domain = MarketplaceDomain.kept.includes(:marketplace).find_by(host: host)
      return domain&.marketplace if domain

      # Backwards compat: allow old mapping via marketplaces.custom_domain.
      Marketplace.kept.find_by(custom_domain: host)
    end

    def tenant_required?
      ActiveModel::Type::Boolean.new.cast(ENV.fetch("BACKEND_TENANT_REQUIRED", "true"))
    end

    def override_subdomain_for(request)
      return "" unless local_override_request?(request)

      request.get_header("HTTP_X_MARKETPLACE_SUBDOMAIN").to_s.downcase
    end

    def local_override_request?(request)
      host = request.host.to_s.downcase
      localhost = host == "localhost" || host == "127.0.0.1"
      private_network = host.match?(/\A10\./) || host.match?(/\A192\.168\./) || host.match?(/\A172\.(1[6-9]|2\d|3[0-1])\./)

      localhost || private_network || Rails.env.development?
    end

    def unknown_tenant
      body = { error: "unknown_tenant" }.to_json
      headers = {
        "Content-Type" => "application/json",
        "Cache-Control" => "no-store"
      }
      [404, headers, [body]]
    end
  end
end
