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
      if request.path.start_with?("/api/v1/admin")
        return @app.call(env)
      end

      origin = RequestOrigin.extract(request)
      effective_host = origin.host.to_s.downcase
      effective_host = "localhost" if effective_host == "127.0.0.1"
      effective_port = origin.port.to_i

      Current.request_host = effective_host
      Current.marketplace = resolve_marketplace(request, host: effective_host, port: effective_port)
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

    def resolve_marketplace(request, host:, port:)
      org = Current.organization
      return nil if org.nil?

      override = override_subdomain_for(request, host: host)
      if override.present?
        marketplace = Marketplace.kept.find_by(organization_id: org.id, subdomain: override)
        return marketplace if marketplace
      end

      unless localhostish?(host)
        domain = MarketplaceDomain.kept.includes(:marketplace).find_by(host: host)
        if domain&.marketplace&.organization_id == org.id
          return domain.marketplace
        end

        direct = Marketplace.kept.find_by(organization_id: org.id, custom_domain: host)
        return direct if direct
      end

      Marketplace.kept.where(organization_id: org.id).order(:name).first
    end

    def tenant_required?
      ActiveModel::Type::Boolean.new.cast(ENV.fetch("BACKEND_TENANT_REQUIRED"))
    end

    def override_subdomain_for(request, host:)
      return "" unless local_override_request?(request, host: host)

      request.get_header("HTTP_X_MARKETPLACE_SUBDOMAIN").to_s.downcase
    end

    def local_override_request?(_request, host:)
      localhost = host == "localhost" || host == "127.0.0.1"
      private_network = host.match?(/\A10\./) || host.match?(/\A192\.168\./) || host.match?(/\A172\.(1[6-9]|2\d|3[0-1])\./)

      localhost || private_network || Rails.env.development?
    end

    def localhostish?(host)
      host == "localhost" || host == "127.0.0.1"
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
