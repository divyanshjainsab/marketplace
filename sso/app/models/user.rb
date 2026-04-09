class User < ApplicationRecord
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :lockable,
         :two_factor_authenticatable,
         :two_factor_backupable,
         otp_secret_encryption_key: Sso::Secrets.otp_secret_encryption_key

  before_validation :ensure_external_id, on: :create
  before_validation :ensure_two_factor_seed, on: :create

  validates :external_id, presence: true, uniqueness: true

  def jwt_subject
    external_id
  end

  private

  def ensure_external_id
    self.external_id = SecureRandom.uuid if external_id.blank?
  end

  def ensure_two_factor_seed
    self.otp_required_for_login = true if otp_required_for_login.nil? || otp_required_for_login == false
    self.otp_secret ||= self.class.generate_otp_secret
  end
end
