require "jwt"
require "json"

module Sso
  class OidcIdTokenVerifier
    Verification = Struct.new(:ok, :payload, :error, keyword_init: true) do
      def ok?
        ok == true
      end
    end

    JWKS_CACHE_KEY = "sso:oidc:jwks"

    def self.verify(id_token:, client_id:, nonce:)
      new(id_token: id_token, client_id: client_id, nonce: nonce).verify
    end

    def initialize(id_token:, client_id:, nonce:)
      @id_token = id_token.to_s
      @client_id = client_id.to_s
      @nonce = nonce.to_s
    end

    def verify
      return Verification.new(ok: false, error: "missing_id_token") if @id_token.blank?

      header = JWT.decode(@id_token, nil, false).last
      kid = header["kid"].to_s
      return Verification.new(ok: false, error: "missing_kid") if kid.blank?

      jwk_hash = jwks_keys.find { |k| k["kid"].to_s == kid }
      return Verification.new(ok: false, error: "unknown_kid") if jwk_hash.nil?

      public_key = JWT::JWK.import(jwk_hash).public_key

      payload, = JWT.decode(
        @id_token,
        public_key,
        true,
        {
          algorithm: "RS256",
          iss: issuer,
          verify_iss: true,
          aud: @client_id,
          verify_aud: true
        }
      )

      if @nonce.present? && payload["nonce"].to_s != @nonce
        return Verification.new(ok: false, error: "nonce_mismatch")
      end

      Verification.new(ok: true, payload: payload, error: nil)
    rescue JWT::ExpiredSignature
      Verification.new(ok: false, error: "expired")
    rescue JWT::DecodeError => e
      Verification.new(ok: false, error: "invalid:#{e.message}")
    rescue Faraday::Error => e
      Verification.new(ok: false, error: "sso_unreachable:#{e.class.name}")
    end

    private

    def issuer
      ENV.fetch("SSO_OIDC_ISSUER").delete_suffix("/")
    end

    def jwks_url
      base = ENV.fetch("SSO_BASE_URL").delete_suffix("/")
      "#{base}/jwks.json"
    end

    def jwks_keys
      Rails.cache.fetch(JWKS_CACHE_KEY, expires_in: 5.minutes) do
        response = Faraday.get(jwks_url) do |req|
          req.headers["Accept"] = "application/json"
        end
        body = response.body.is_a?(Hash) ? response.body : (JSON.parse(response.body.to_s) rescue {})
        Array(body["keys"] || [])
      end
    end
  end
end
