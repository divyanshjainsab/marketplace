class CatalogAttribute < ApplicationRecord
  self.table_name = "attributes"

  DATA_TYPES = %w[string integer decimal boolean enum json array].freeze

  include SoftDeletable
  include Audited

  has_many :product_type_attributes,
           foreign_key: :attribute_id,
           inverse_of: :catalog_attribute,
           dependent: :restrict_with_exception

  before_validation :normalize_code
  before_validation :assign_default_code

  validates :name, presence: true
  validates :code,
            presence: true,
            uniqueness: { conditions: -> { kept } },
            format: { with: /\A[a-z][a-z0-9_]*\z/ }
  validates :data_type, presence: true, inclusion: { in: DATA_TYPES }

  private

  def normalize_code
    self.code = code.to_s.strip.downcase.presence if code.present?
  end

  def assign_default_code
    self.code = name.to_s.parameterize(separator: "_").presence if code.blank?
  end
end

