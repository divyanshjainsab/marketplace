class Inventory < ApplicationRecord
  belongs_to :marketplace
  belongs_to :listing

  include TenantScoped
  include SoftDeletable
  include Audited

  validates :quantity_on_hand, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :marketplace_matches_listing

  after_save :sync_listing_inventory_count

  private

  def marketplace_matches_listing
    return if listing.blank? || marketplace.blank?

    return if listing.marketplace_id == marketplace_id

    errors.add(:marketplace_id, "must match listing marketplace")
  end

  def sync_listing_inventory_count
    return if listing.blank?
    return if listing.inventory_count.to_i == quantity_on_hand.to_i

    listing.update_columns(inventory_count: quantity_on_hand, updated_at: Time.current)
  end
end

