class Address < ApplicationRecord
  ADDRESS_TYPES = %w[home work other].freeze

  belongs_to :user

  scope :kept, -> { where(discarded_at: nil) }
  scope :discarded, -> { where.not(discarded_at: nil) }

  validates :address_type, presence: true, inclusion: { in: ADDRESS_TYPES }
  validates :line1, :city, :state, :country, :zip_code, presence: true
  validates :line1, length: { maximum: 200 }
  validates :line2, length: { maximum: 200 }, allow_blank: true
  validates :city, :state, :country, length: { maximum: 100 }
  validates :zip_code, length: { maximum: 32 }

  def discard!
    update!(discarded_at: Time.current)
  end
end

