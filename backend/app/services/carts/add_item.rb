module Carts
  class AddItem
    def self.call(cart:, variant_id:, quantity: 1)
      new(cart: cart, variant_id: variant_id, quantity: quantity).call
    end

    def initialize(cart:, variant_id:, quantity:)
      @cart = cart
      @variant_id = variant_id.to_i
      @quantity = quantity.to_i
    end

    def call
      raise ActiveRecord::RecordNotFound, "Cart context is required" if @cart.nil?
      raise ActiveRecord::RecordNotFound, "Variant is required" unless @variant_id.positive?

      listing = Listing.kept.find_by!(marketplace_id: @cart.marketplace_id, variant_id: @variant_id)
      ensure_listing_is_available!(listing)

      increment_by = @quantity.positive? ? @quantity : 1

      item = @cart.cart_items.kept.find_or_initialize_by(variant_id: @variant_id)
      item.quantity = (item.quantity || 0) + increment_by
      ensure_inventory_allows!(listing, item)

      item.save!
      item
    end

    private

    def ensure_listing_is_available!(listing)
      blocked = %w[inactive archived disabled]
      return unless blocked.include?(listing.status.to_s.downcase)

      item = @cart.cart_items.new(variant_id: @variant_id, quantity: 1)
      item.errors.add(:base, "Listing is not available")
      raise ActiveRecord::RecordInvalid.new(item)
    end

    def ensure_inventory_allows!(listing, item)
      available = listing.inventory_count.to_i
      return if available >= item.quantity

      item.errors.add(:quantity, "exceeds available inventory")
      raise ActiveRecord::RecordInvalid.new(item)
    end
  end
end

