class Cart < ApplicationRecord
  include TenantScoped
  include SoftDeletable

  belongs_to :marketplace
  belongs_to :user, optional: true

  has_many :cart_items, dependent: :destroy
  has_many :variants, through: :cart_items

  before_validation :ensure_session_id

  validates :session_id, presence: true, uniqueness: { scope: :marketplace_id, conditions: -> { kept } }
  validates :user_id, uniqueness: { scope: :marketplace_id, conditions: -> { kept } }, allow_nil: true

  private

  def ensure_session_id
    self.session_id = SecureRandom.uuid if session_id.blank?
  end
end

