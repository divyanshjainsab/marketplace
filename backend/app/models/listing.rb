class Listing < ApplicationRecord
  INR_CURRENCY = "INR"

  belongs_to :marketplace
  belongs_to :product
  belongs_to :variant

  include TenantScoped
  include SoftDeletable
  include Audited

  before_validation :default_currency_to_inr

  validates :variant_id, uniqueness: { scope: :marketplace_id, conditions: -> { kept } }
  validates :price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :currency, inclusion: { in: [INR_CURRENCY] }

  private

  def default_currency_to_inr
    self.currency = INR_CURRENCY if currency.blank?
    self.currency = currency.to_s.upcase
  end
end
