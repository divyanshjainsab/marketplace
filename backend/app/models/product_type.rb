class ProductType < ApplicationRecord
  include SoftDeletable
  include Audited

  has_many :products, dependent: :restrict_with_exception

  validates :name, presence: true
  validates :code, presence: true, uniqueness: { conditions: -> { kept } }
end
