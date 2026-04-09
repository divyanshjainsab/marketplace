class Variant < ApplicationRecord
  belongs_to :product

  include SoftDeletable
  include Audited
  include PgSearch::Model

  has_many :listings, dependent: :restrict_with_exception

  validates :name, presence: true
  validates :sku, presence: true, uniqueness: { conditions: -> { kept } }
  validates :image_url, length: { maximum: 4096 }, allow_nil: true

  pg_search_scope :search_suggestions,
                  against: %i[name sku],
                  using: { tsearch: { prefix: true } }
end
