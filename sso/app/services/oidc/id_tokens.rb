module Oidc
  class IdTokens
    def self.issue(user:, client_id:, nonce:, claims: {})
      new.issue(user: user, client_id: client_id, nonce: nonce, claims: claims)
    end

    def issue(user:, client_id:, nonce:, claims:)
      now = Time.now.to_i
      exp = now + Config.id_token_ttl_seconds

      payload = {
        iss: Config.issuer,
        aud: client_id,
        iat: now,
        exp: exp,
        jti: SecureRandom.uuid,
        sub: user.external_id,
        nonce: nonce,
        email: user.email,
        name: user.name,
        roles: Array(claims["roles"] || claims[:roles] || [])
      }.compact

      key = SigningKey.current
      headers = {
        typ: "JWT",
        kid: key.jwk.kid
      }

      JWT.encode(payload, key.private_key, "RS256", headers)
    end
  end
end
