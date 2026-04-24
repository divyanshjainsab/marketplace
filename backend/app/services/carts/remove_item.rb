module Carts
  class RemoveItem
    def self.call(cart:, variant_id:)
      new(cart: cart, variant_id: variant_id).call
    end

    def initialize(cart:, variant_id:)
      @cart = cart
      @variant_id = variant_id.to_i
    end

    def call
      raise ActiveRecord::RecordNotFound, "Cart context is required" if @cart.nil?
      raise ActiveRecord::RecordNotFound, "Variant is required" unless @variant_id.positive?

      item = @cart.cart_items.kept.find_by!(variant_id: @variant_id)
      item.discard
      item
    end
  end
end

