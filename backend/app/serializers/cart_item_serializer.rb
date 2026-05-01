class CartItemSerializer < BaseSerializer
  def as_json
    listing_by_variant_id = context[:listing_by_variant_id] || {}
    listing = listing_by_variant_id[record.variant_id]
    blocked_statuses = %w[inactive archived disabled]

    unit_price_cents = listing&.price_cents
    line_total_cents = unit_price_cents.present? ? unit_price_cents * record.quantity : nil
    inventory_count = listing&.inventory_on_hand

    {
      id: record.id,
      variant_id: record.variant_id,
      quantity: record.quantity,
      unit_price_cents: unit_price_cents,
      currency: listing&.currency,
      line_total_cents: line_total_cents,
      inventory_count: inventory_count,
      available: listing.present? && inventory_count.to_i >= record.quantity && !blocked_statuses.include?(listing.status.to_s.downcase),
      listing: listing.present? ? ListingSerializer.one(listing) : nil
    }
  end
end
