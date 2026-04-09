module Sso
  class JwtTokens
    ALGORITHM = "HS256"

    Decoded = Struct.new(:payload, :token, keyword_init: true)

    def self.issue(user:, ttl_seconds: nil)
      new.issue(user: user, ttl_seconds: ttl_seconds)
    end

    def self.decode(token:)
      new.decode(token: token)
    end

    def issue(user:, ttl_seconds:)
      now = Time.now.to_i
      ttl = Integer(ttl_seconds || Secrets.jwt_ttl_seconds)
      exp = now + ttl

      payload = {
        iss: issuer,
        iat: now,
        exp: exp,
        jti: SecureRandom.uuid,
        sub: user.jwt_subject,
        email: user.email
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
