module Sso
  class TokenValidator
    Validation = Struct.new(
      :valid,
      :sso_user_id,
      :external_id,
      :email,
      :name,
      :roles,
      :org_id,
      :exp,
      :error,
      keyword_init: true
    )

    def self.call(token:)
      new(token: token).call
    end

    def initialize(token:)
      @token = token.to_s.strip
      @cache = self.class.cache_store
    end

    def call
      return Validation.new(valid: false, error: "missing_token") if @token.blank?

      cached = @cache.read(cache_key)
      return cached if cached

      response = Connection.client.post("/validate_token") do |req|
        req.headers["Authorization"] = "Bearer #{@token}"
      end

      validation = parse_validation(response)
      @cache.write(cache_key, validation, expires_in: cache_ttl_seconds(validation))
      validation
    rescue Faraday::Error => e
      Validation.new(valid: false, error: "sso_unreachable:#{e.class.name}")
    end

    def self.cache_store
      @cache_store ||= ActiveSupport::Cache::MemoryStore.new(size: 32.megabytes)
    end

    private

    def cache_key
      "sso:validate_token:#{Digest::SHA256.hexdigest(@token)}"
    end

    def parse_validation(response)
      body = response.body.is_a?(Hash) ? response.body : {}

      if response.status == 200 && body["valid"] == true
        user = body["user"] || {}
        return Validation.new(
          valid: true,
          sso_user_id: user["id"],
          external_id: user["external_id"],
          email: user["email"],
          name: user["name"],
          roles: body["roles"] || user["roles"] || [],
          org_id: body["org_id"] || user["org_id"],
          exp: body["exp"],
          error: nil
        )
      end

      Validation.new(
        valid: false,
        error: body["error"].presence || "invalid"
      )
    end

    def cache_ttl_seconds(validation)
      return 5 if validation.valid == false

      exp = validation.exp.to_i
      return 60 if exp <= 0

      seconds = exp - Time.now.to_i
      [[seconds, 5].max, 300].min
    end
  end
end
