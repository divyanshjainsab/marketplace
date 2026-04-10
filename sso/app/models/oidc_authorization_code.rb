require "digest"

class OidcAuthorizationCode < ApplicationRecord
  belongs_to :user

  scope :active, -> { where(used_at: nil).where("expires_at > ?", Time.current) }

  def self.issue!(
    user:,
    client_id:,
    redirect_uri:,
    scope:,
    code_challenge:,
    code_challenge_method:,
    nonce:,
    claims:,
    request:
  )
    raw = SecureRandom.hex(32)
    create!(
      code_digest: Digest::SHA256.hexdigest(raw),
      user: user,
      client_id: client_id,
      redirect_uri: redirect_uri,
      scope: scope,
      code_challenge: code_challenge,
      code_challenge_method: code_challenge_method,
      nonce: nonce,
      claims: claims || {},
      ip_address: request&.remote_ip,
      user_agent: request&.user_agent.to_s.first(500),
      expires_at: 60.seconds.from_now
    )
    raw
  end

  def self.consume!(code:, client_id:, redirect_uri:)
    digest = Digest::SHA256.hexdigest(code.to_s)
    record = lock.where(code_digest: digest).first
    raise ActiveRecord::RecordNotFound if record.nil?
    raise Oidc::Errors::InvalidGrant, "expired_code" if record.expires_at <= Time.current
    raise Oidc::Errors::InvalidGrant, "code_already_used" if record.used_at.present?
    raise Oidc::Errors::InvalidGrant, "client_mismatch" unless record.client_id == client_id
    raise Oidc::Errors::InvalidGrant, "redirect_uri_mismatch" unless record.redirect_uri == redirect_uri
    record
  end
end
