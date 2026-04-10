require "digest"

class UserSession < ApplicationRecord
  belongs_to :user

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }

  def self.digest(token)
    Digest::SHA256.hexdigest(token.to_s)
  end

  def revoke!(reason: "logout")
    update!(
      revoked_at: Time.current,
      revoked_reason: reason,
      last_used_at: Time.current
    )
  end
end

