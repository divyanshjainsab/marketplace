require "digest"

module Sso
  class RefreshTokens
    TokenPair = Struct.new(:access_token, :refresh_token, :access_exp, :refresh_exp, keyword_init: true)
    Rotation = Struct.new(:user, :token_pair, keyword_init: true)

    def self.issue(user:, request:, claims: {})
      new.issue(user: user, request: request, claims: claims)
    end

    def self.rotate(token:, request:)
      new.rotate(token: token, request: request)
    end

    def issue(user:, request:, claims:)
      raw_refresh_token = SecureRandom.hex(48)
      refresh_exp = Time.current + Secrets.refresh_token_ttl_seconds

      RefreshToken.create!(
        user: user,
        token_digest: digest(raw_refresh_token),
        expires_at: refresh_exp,
        org_id: claims[:org_id],
        roles: Array(claims[:roles] || []),
        ip_address: request.remote_ip,
        user_agent: request.user_agent.to_s.first(500)
      )

      access_token = JwtTokens.issue(user: user, claims: claims)
      decoded = JwtTokens.decode(token: access_token)

      TokenPair.new(
        access_token: access_token,
        refresh_token: raw_refresh_token,
        access_exp: Time.at(decoded.payload.fetch("exp")),
        refresh_exp: refresh_exp
      )
    end

    def rotate(token:, request:)
      record = RefreshToken.active.find_by!(token_digest: digest(token))
      user = record.user

      RefreshToken.transaction do
        record.update!(
          revoked_at: Time.current,
          revoked_reason: "rotated",
          last_used_at: Time.current
        )

        Rotation.new(
          user: user,
          token_pair: issue(
            user: user,
            request: request,
            claims: { org_id: record.org_id, roles: record.roles }
          )
        )
      end
    end

    private

    def digest(token)
      Digest::SHA256.hexdigest(token.to_s)
    end
  end
end
