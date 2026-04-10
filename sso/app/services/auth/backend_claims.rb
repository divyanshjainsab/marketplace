require "net/http"
require "json"

module Auth
  class BackendClaims
    Result = Struct.new(:allowed, :org_id, :roles, :error, keyword_init: true) do
      def allowed?
        allowed == true
      end
    end

    def self.fetch(user:, org_slug:)
      new(user: user, org_slug: org_slug).fetch
    end

    def initialize(user:, org_slug:)
      @user = user
      @org_slug = org_slug.to_s
    end

    def fetch
      return Result.new(allowed: false, error: "missing_org_slug") if org_slug.blank?

      Rails.cache.fetch(cache_key, expires_in: 30) do
        uri = URI.join(base_url, "/auth/sso/claims")
        req = Net::HTTP::Post.new(uri)
        req["Content-Type"] = "application/json"
        req["Accept"] = "application/json"
        req["X-SSO-Backend-Secret"] = shared_secret

        req.body = {
          external_id: user.external_id,
          email: user.email,
          name: user.name,
          org_slug: org_slug
        }.to_json

        res = http_client(uri).request(req)
        body = JSON.parse(res.body.to_s) rescue {}

        if res.code.to_i == 200
          return Result.new(
            allowed: body["allowed"] == true,
            org_id: body["org_id"],
            roles: Array(body["roles"] || []),
            error: nil
          )
        end

        Result.new(allowed: false, error: body["error"].presence || "backend_error:#{res.code}")
      end
    rescue => e
      Result.new(allowed: false, error: "backend_unreachable:#{e.class.name}")
    end

    private

    attr_reader :user, :org_slug

    def cache_key
      "sso:backend_claims:#{user.external_id}:#{org_slug}"
    end

    def base_url
      ENV.fetch("SSO_BACKEND_BASE_URL", "http://backend:3000")
    end

    def shared_secret
      ENV.fetch("SSO_BACKEND_SHARED_SECRET", "")
    end

    def http_client(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.open_timeout = 2
      http.read_timeout = 3
      http
    end
  end
end

