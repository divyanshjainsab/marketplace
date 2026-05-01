class Product < ApplicationRecord
  belongs_to :product_type
  belongs_to :category

  include HasCloudinaryImage
  include SoftDeletable
  include Audited
  include PgSearch::Model

  has_many :variants, dependent: :restrict_with_exception
  has_many :listings, dependent: :restrict_with_exception

  validates :name, presence: true
  validates :sku, presence: true, uniqueness: { conditions: -> { kept } }

  validate :category_must_match_product_type
  validate :metadata_conforms_to_schema

  pg_search_scope :suggest,
                  against: %i[name sku],
                  using: {
                    tsearch: { prefix: true, tsvector_column: "search_document" },
                    trigram: { threshold: 0.2 }
                  }

  private

  def category_must_match_product_type
    return if category.blank? || product_type.blank?
    return if category.product_type_id == product_type_id

    errors.add(:category_id, "must belong to the same product type")
  end

  def metadata_conforms_to_schema
    return if product_type.blank?

    schema = product_type.product_type_attributes.kept.where(variant_level: false).includes(:catalog_attribute)
    CatalogAttributes::SchemaValidator.validate(values: metadata, schema: schema, errors: errors, field: :metadata)
  end
end
