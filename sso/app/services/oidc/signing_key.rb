require "openssl"
require "digest"

module Oidc
  class SigningKey
    def self.current
      @current ||= new
    end

    def private_key
      @private_key ||= load_private_key
    end

    def jwk
      @jwk ||= begin
        kid = ENV["SSO_OIDC_SIGNING_KID"].to_s.presence
        jwk = JWT::JWK.new(private_key, kid: kid)
        # If kid wasn't provided, derive a stable one from the public material.
        if jwk.kid.blank?
          derived = Digest::SHA256.hexdigest(jwk.export.slice("n", "e").to_json)[0, 16]
          jwk = JWT::JWK.new(private_key, kid: derived)
        end
        jwk
      end
    end

    def jwks_payload
      { keys: [jwk.export] }
    end

    private

    def load_private_key
      pem = ENV["SSO_OIDC_SIGNING_PRIVATE_KEY_PEM"].to_s
      if pem.present?
        return OpenSSL::PKey::RSA.new(pem)
      end

      raise KeyError, "missing SSO_OIDC_SIGNING_PRIVATE_KEY_PEM" if Rails.env.production?

      Rails.logger.warn("[oidc] Missing SSO_OIDC_SIGNING_PRIVATE_KEY_PEM; generating ephemeral RSA key (dev only).")
      OpenSSL::PKey::RSA.new(2048)
    end
  end
end
