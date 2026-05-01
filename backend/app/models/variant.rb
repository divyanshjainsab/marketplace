class Variant < ApplicationRecord
  belongs_to :product

  include HasCloudinaryImage
  include SoftDeletable
  include Audited
  include PgSearch::Model

  has_many :listings, dependent: :restrict_with_exception
  has_many :variant_images, dependent: :restrict_with_exception

  validates :name, presence: true
  validates :sku, presence: true, uniqueness: { conditions: -> { kept } }

  validate :options_conforms_to_schema

  pg_search_scope :search_suggestions,
                  against: %i[name sku],
                  using: { tsearch: { prefix: true } }

  private

  def options_conforms_to_schema
    return if product.blank?

    product_type = product.product_type
    return if product_type.blank?

    schema = product_type.product_type_attributes.kept.where(variant_level: true).includes(:catalog_attribute)
    CatalogAttributes::SchemaValidator.validate(values: options, schema: schema, errors: errors, field: :options)
  end
end
