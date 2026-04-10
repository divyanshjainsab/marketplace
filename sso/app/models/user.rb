class User < ApplicationRecord
  serialize :otp_backup_codes, coder: JSON

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
end
