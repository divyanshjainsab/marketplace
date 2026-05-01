class Listing < ApplicationRecord
  INR_CURRENCY = "INR"

  belongs_to :marketplace
  belongs_to :product
  belongs_to :variant
  has_one :inventory, dependent: :destroy

  include HasCloudinaryImage
  include TenantScoped
  include SoftDeletable
  include Audited

  before_validation :default_currency_to_inr
  after_create :ensure_inventory_record!

  validates :variant_id, uniqueness: { scope: :marketplace_id, conditions: -> { kept } }
  validates :price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :inventory_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :currency, inclusion: { in: [INR_CURRENCY] }

  validate :variant_must_belong_to_product

  def effective_image_asset
    image_asset || variant&.image_asset || product&.image_asset
  end

  def effective_image_source
    return "listing" if image_asset.present?
    return "variant" if variant&.image_asset.present?
    return "product" if product&.image_asset.present?

    nil
  end

  def inventory_on_hand
    inventory&.quantity_on_hand || inventory_count.to_i
  end

  private

  def ensure_inventory_record!
    return if inventory.present?

    create_inventory!(marketplace: marketplace, quantity_on_hand: inventory_count.to_i)
  end

  def variant_must_belong_to_product
    return if variant.blank? || product.blank?
    return if variant.product_id == product_id

    errors.add(:variant_id, "must belong to the listing product")
  end

  def default_currency_to_inr
    self.currency = INR_CURRENCY if currency.blank?
    self.currency = currency.to_s.upcase
  end
end
