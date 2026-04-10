class User < ApplicationRecord
  serialize :otp_backup_codes, coder: JSON

  has_many :addresses, dependent: :destroy
  devise :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :lockable,
         :two_factor_authenticatable,
         :two_factor_backupable,
         otp_secret_encryption_key: Sso::Secrets.otp_secret_encryption_key

  before_validation :ensure_external_id, on: :create

  validates :external_id, presence: true, uniqueness: true
  validates :email_verified, inclusion: { in: [true, false] }

  has_many :email_otp_challenges, dependent: :destroy

  validates :phone_number, length: { maximum: 32 }, allow_blank: true
  validates :avatar_url, length: { maximum: 500 }, allow_blank: true
  validate :password_complexity, if: -> { password.present? }

  def jwt_subject
    external_id
  end

  def jwt_roles
    ["user"]
  end

  def jwt_org_id
    nil
  end

  def active_for_authentication?
    super && email_verified?
  end

  def inactive_message
    return :unverified_email unless email_verified?

    super
  end

  private

  def ensure_external_id
    self.external_id = SecureRandom.uuid if external_id.blank?
  end

  def password_complexity
    value = password.to_s

    errors.add(:password, "must be at least 8 characters") if value.length < 8
    errors.add(:password, "must include an uppercase letter") unless value.match?(/[A-Z]/)
    errors.add(:password, "must include a lowercase letter") unless value.match?(/[a-z]/)
    errors.add(:password, "must include a number") unless value.match?(/\d/)
    errors.add(:password, "must include a special character") unless value.match?(/[^A-Za-z0-9]/)
  end
end
