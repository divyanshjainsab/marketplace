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

      Current.marketplace = resolve_marketplace(request)

      @app.call(env)
    ensure
      Current.reset
    end

    private

    def resolve_marketplace(request)
      host = request.host.to_s.downcase
      override = request.get_header("HTTP_X_MARKETPLACE_SUBDOMAIN").to_s.downcase
      override = ENV["DEFAULT_MARKETPLACE_SUBDOMAIN"].to_s.downcase if override.empty?

      # Prefer explicit overrides for localhost/IP-based dev requests.
      if override.present?
        return Marketplace.kept.find_by(subdomain: override)
      end

      # Try custom domains first.
      marketplace = Marketplace.kept.find_by(custom_domain: host)
      return marketplace if marketplace

      # Basic subdomain resolution.
      parts = host.split(".")
      return nil if parts.length < 3 # e.g. "example.com" or "localhost"

      Marketplace.kept.find_by(subdomain: parts.first)
    end
  end
end
