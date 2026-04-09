class User < ApplicationRecord
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :two_factor_authenticatable,
         :two_factor_backupable,
         otp_secret_encryption_key: Sso::Secrets.otp_secret_encryption_key

  before_validation :ensure_external_id, on: :create

  validates :external_id, presence: true, uniqueness: true

  def jwt_subject
    external_id
  end

  private

  def ensure_external_id
    self.external_id = SecureRandom.uuid if external_id.blank?
  end
end
