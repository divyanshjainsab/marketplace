class ProductTypeAttribute < ApplicationRecord
  include SoftDeletable
  include Audited

  belongs_to :product_type
  belongs_to :catalog_attribute,
             class_name: "CatalogAttribute",
             foreign_key: :attribute_id,
             inverse_of: :product_type_attributes

  validates :attribute_id, uniqueness: { scope: :product_type_id, conditions: -> { kept } }
  validates :required, inclusion: { in: [true, false] }
  validates :variant_level, inclusion: { in: [true, false] }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validate :config_must_be_object
  validate :allowed_values_matches_data_type

  def code
    catalog_attribute&.code
  end

  private

  def config_must_be_object
    errors.add(:config, "must be an object") unless config.is_a?(Hash)
  end

  def allowed_values_matches_data_type
    return unless config.is_a?(Hash)

    allowed_values = config["allowed_values"]
    return if allowed_values.blank?

    unless allowed_values.is_a?(Array)
      errors.add(:config, "allowed_values must be an array")
      return
    end

    return if catalog_attribute.blank?

    return if %w[enum string integer].include?(catalog_attribute.data_type)

    errors.add(:config, "allowed_values is only valid for enum/string/integer data types")
  end
end
