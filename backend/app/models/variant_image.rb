class VariantImage < ApplicationRecord
  belongs_to :variant

  include HasCloudinaryImage
  include SoftDeletable
  include Audited

  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :position, uniqueness: { scope: :variant_id, conditions: -> { kept } }
end

