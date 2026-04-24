class CartItem < ApplicationRecord
  include SoftDeletable

  belongs_to :cart
  belongs_to :variant

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :variant_id, uniqueness: { scope: :cart_id, conditions: -> { kept } }
end

