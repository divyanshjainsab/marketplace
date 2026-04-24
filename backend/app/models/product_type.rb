class ProductType < ApplicationRecord
  include SoftDeletable
  include Audited

  has_many :products, dependent: :restrict_with_exception

  before_validation :assign_default_code

  validates :name, presence: true
  validates :code, presence: true, uniqueness: { conditions: -> { kept } }

  private

  def assign_default_code
    self.code = name.to_s.parameterize(separator: "_").presence if code.blank?
  end
end
