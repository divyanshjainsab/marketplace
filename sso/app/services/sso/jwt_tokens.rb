module Sso
  class JwtTokens
    ALGORITHM = "HS256"

    Decoded = Struct.new(:payload, :token, keyword_init: true)

    def self.issue(user:, ttl_seconds: nil, claims: {})
      new.issue(user: user, ttl_seconds: ttl_seconds, claims: claims)
    end

    def self.decode(token:)
      new.decode(token: token)
    end

    def issue(user:, ttl_seconds:, claims:)
      now = Time.now.to_i
      ttl = Integer(ttl_seconds || Auth::JwtService.access_ttl_seconds)
      exp = now + ttl

      payload = {
        typ: "access",
        iss: issuer,
        iat: now,
        exp: exp,
        jti: SecureRandom.uuid,
        user_id: user.id,
        sub: user.jwt_subject,
        email: user.email,
        name: user.name,
        roles: Array(claims[:roles].presence || user.jwt_roles),
        org_id: claims.key?(:org_id) ? claims[:org_id] : user.jwt_org_id
      }

      JWT.encode(payload, secret, ALGORITHM)
    end

    def decode(token:)
      payload, = JWT.decode(
        token,
        secret,
        true,
        {
          algorithm: ALGORITHM,
          iss: issuer,
          verify_iss: true
        }
      )

      raise JWT::DecodeError, "invalid_token_type" unless payload["typ"] == "access"

      Decoded.new(payload: payload, token: token)
    end

    private

    def secret
      Secrets.jwt_secret
    end

    def issuer
      Secrets.jwt_issuer
    end
  end
end
