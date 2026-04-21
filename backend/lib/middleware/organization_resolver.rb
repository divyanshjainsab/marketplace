module Middleware
  class OrganizationResolver
    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)

      return @app.call(env) if request.path == "/up"
      return @app.call(env) if request.path.start_with?("/auth/oidc/")
      return @app.call(env) if request.path.start_with?("/auth/session")

      origin = RequestOrigin.extract(request)
      host = origin.host.to_s.downcase
      host = "localhost" if host == "127.0.0.1"
      port = origin.port.to_i

      Current.request_host = host
      Current.organization = resolve_organization(host: host, port: port)
      Current.org_id = Current.organization&.id

      env["app.request_host"] = Current.request_host
      env["app.current_org_id"] = Current.org_id
      env["app.current_organization"] = Current.organization

      if org_required?(request) && Current.organization.nil?
        return unknown_org
      end

      @app.call(env)
    ensure
      Current.reset
    end

    private

    def resolve_organization(host:, port:)
      return nil if host.blank?

      effective_host = host.to_s.downcase
      effective_host = "localhost" if effective_host == "127.0.0.1"

      if effective_host == "localhost"
        return nil unless port.positive?
        return Organization.kept.find_by(dev_port: port)
      end

      subdomain = extract_subdomain(effective_host)
      return nil if subdomain.blank?

      Organization.kept.find_by(subdomain: subdomain)
    end

    def extract_subdomain(host)
      parts = host.to_s.split(".")
      return "" if parts.length < 3

      sub = parts.first.to_s.downcase
      return "" if sub.blank? || sub == "www"

      sub
    end

    def org_required?(request)
      request.path.start_with?("/api/v1/admin")
    end

    def unknown_org
      body = { error: "unknown_org" }.to_json
      headers = {
        "Content-Type" => "application/json",
        "Cache-Control" => "no-store"
      }
      [404, headers, [body]]
    end
  end
end
