class OidcLoginState < ApplicationRecord
  scope :active, -> { where(used_at: nil).where("expires_at > ?", Time.current) }

  def expired?
    expires_at <= Time.current
  end

  def use!
    update!(used_at: Time.current)
  end
end

