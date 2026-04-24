class CartSerializer < BaseSerializer
  def as_json
    cart_items = record.cart_items.kept.order(:created_at).includes(:variant)
    variant_ids = cart_items.map(&:variant_id)

    listings_by_variant_id = Listing.kept
      .where(marketplace_id: record.marketplace_id, variant_id: variant_ids)
      .includes(:variant, product: %i[product_type category])
      .index_by(&:variant_id)

    subtotal_cents = cart_items.sum do |item|
      listing = listings_by_variant_id[item.variant_id]
      (listing&.price_cents || 0) * item.quantity
    end

    {
      id: record.id,
      marketplace_id: record.marketplace_id,
      user_id: record.user_id,
      session_id: record.session_id,
      item_count: cart_items.sum(&:quantity),
      subtotal_cents: subtotal_cents,
      items: CartItemSerializer.many(cart_items, context: { listing_by_variant_id: listings_by_variant_id })
    }
  end
end

