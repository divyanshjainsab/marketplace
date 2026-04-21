module Oidc
  class Config
    def self.issuer
      ENV.fetch("SSO_OIDC_ISSUER").delete_suffix("/")
    end

    def self.id_token_ttl_seconds
      Integer(ENV.fetch("SSO_OIDC_ID_TOKEN_TTL_SECONDS"))
    end
  end
end
