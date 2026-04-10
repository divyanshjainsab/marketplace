module Auth
  class JwtService
    def self.issue(user:, ttl_seconds: nil)
      Sso::JwtTokens.issue(user: user, ttl_seconds: ttl_seconds || access_ttl_seconds)
    end

    def self.decode(token:)
      Sso::JwtTokens.decode(token: token)
    end

    def self.access_ttl_seconds
      (ENV["SSO_JWT_TTL_SECONDS"].presence || 900).to_i
    end
  end
end
