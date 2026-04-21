class Auth::SessionManager
  SessionPair = Struct.new(:access_token, :access_exp, :refresh_token, :refresh_exp, :session, keyword_init: true)

  def self.issue(user:, org_id:, roles:, request:)
    new.issue(user: user, org_id: org_id, roles: roles, request: request)
  end

  def self.rotate(refresh_token:, request:)
    new.rotate(refresh_token: refresh_token, request: request)
  end

  def issue(user:, org_id:, roles:, request:)
    raw_refresh = SecureRandom.hex(48)
    refresh_exp = refresh_ttl_seconds.seconds.from_now

    session = UserSession.create!(
      user: user,
      refresh_token_digest: UserSession.digest(raw_refresh),
      org_id: org_id,
      roles: Array(roles || []),
      expires_at: refresh_exp,
      ip_address: request.remote_ip,
      user_agent: request.user_agent.to_s.first(500)
    )

    access_token = Auth::SessionTokens.issue(
      user: user,
      session_id: session.id,
      org_id: org_id,
      roles: session.roles
    )
    decoded = Auth::SessionTokens.decode(token: access_token)

    SessionPair.new(
      access_token: access_token,
      access_exp: Time.at(decoded.payload.fetch("exp")),
      refresh_token: raw_refresh,
      refresh_exp: refresh_exp,
      session: session
    )
  end

  def rotate(refresh_token:, request:)
    digest = UserSession.digest(refresh_token)
    record = UserSession.active.find_by!(refresh_token_digest: digest)

    UserSession.transaction do
      record.revoke!(reason: "rotated")
      issue(user: record.user, org_id: record.org_id, roles: record.roles, request: request)
    end
  end

  private

  def refresh_ttl_seconds
    Integer(ENV.fetch("BACKEND_REFRESH_TTL_SECONDS"))
  end
end
