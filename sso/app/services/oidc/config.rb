module Oidc
  class Config
    def self.issuer
      (ENV["SSO_OIDC_ISSUER"].presence || ENV["SSO_PUBLIC_BASE_URL"].presence || "http://localhost:3002").delete_suffix("/")
    end

    def self.id_token_ttl_seconds
      (ENV["SSO_OIDC_ID_TOKEN_TTL_SECONDS"].presence || 300).to_i
    end
  end
end

