require "jwt"

module Auth
  class SessionTokens
    ALGORITHM = "HS256"
    TOKEN_TYPE = "mp_access"

    Decoded = Struct.new(:payload, :header, keyword_init: true)

    def self.issue(user:, session_id:, org_id:, roles:, ttl_seconds: nil)
      new.issue(user: user, session_id: session_id, org_id: org_id, roles: roles, ttl_seconds: ttl_seconds)
    end

    def self.decode(token:)
      new.decode(token: token)
    end

    def issue(user:, session_id:, org_id:, roles:, ttl_seconds:)
      now = Time.now.to_i
      ttl = Integer(ttl_seconds || default_ttl_seconds)
      exp = now + ttl

      payload = {
        typ: TOKEN_TYPE,
        iss: issuer,
        aud: audience,
        iat: now,
        exp: exp,
        jti: SecureRandom.uuid,
        sid: session_id,
        user_id: user.id,
        sub: user.external_id,
        email: user.email,
        name: user.name,
        roles: Array(roles || []),
        org_id: org_id
      }.compact

      JWT.encode(payload, current_secret, ALGORITHM, { kid: current_kid, typ: "JWT" })
    end

    def decode(token:)
      token = token.to_s.strip
      raise JWT::DecodeError, "missing_token" if token.blank?

      header = JWT.decode(token, nil, false).last
      secret = secret_for_kid(header["kid"])

      payload, = JWT.decode(
        token,
        secret,
        true,
        {
          algorithm: ALGORITHM,
          iss: issuer,
          verify_iss: true,
          aud: audience,
          verify_aud: true
        }
      )

      raise JWT::DecodeError, "invalid_token_type" unless payload["typ"] == TOKEN_TYPE

      Decoded.new(payload: payload, header: header)
    end

    private

    def issuer
      (ENV["BACKEND_SESSION_ISSUER"].presence || ENV["BACKEND_PUBLIC_BASE_URL"].presence || "backend").to_s
    end

    def audience
      ENV.fetch("BACKEND_SESSION_AUDIENCE", "marketplace")
    end

    def default_ttl_seconds
      (ENV["BACKEND_SESSION_TTL_SECONDS"].presence || 900).to_i # 15 minutes
    end

    def keyring
      raw = ENV["BACKEND_SESSION_JWT_KEYS"].to_s
      raw = "dev:dev-backend-session-secret" if raw.blank?

      raw.split(",").map(&:strip).reject(&:blank?).map do |pair|
        kid, secret = pair.split(":", 2)
        [kid.to_s, secret.to_s]
      end.select { |kid, secret| kid.present? && secret.present? }.to_h
    end

    def current_kid
      ENV["BACKEND_SESSION_JWT_CURRENT_KID"].presence || keyring.keys.first
    end

    def current_secret
      secret_for_kid(current_kid)
    end

    def secret_for_kid(kid)
      ring = keyring
      if kid.present? && ring[kid].present?
        return ring[kid]
      end

      # Backward/compat fallback: try the first configured secret.
      first = ring.values.first
      raise JWT::DecodeError, "unknown_kid" if first.blank?
      first
    end
  end
end

