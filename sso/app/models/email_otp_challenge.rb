class EmailOtpChallenge < ApplicationRecord
  PURPOSES = %w[email_verification two_factor_recovery].freeze

  belongs_to :user

  validates :purpose, presence: true, inclusion: { in: PURPOSES }
  validates :code_digest, presence: true
  validates :expires_at, presence: true

  scope :active, -> { where(consumed_at: nil).where("expires_at > ?", Time.current) }
  scope :recent_first, -> { order(created_at: :desc) }
end
