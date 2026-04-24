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

  pg_search_scope :suggest,
                  against: %i[name sku],
                  using: {
                    tsearch: { prefix: true, tsvector_column: "search_document" },
                    trigram: { threshold: 0.2 }
                  }
end
