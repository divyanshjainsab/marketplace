class Listing < ApplicationRecord
  belongs_to :marketplace
  belongs_to :product
  belongs_to :variant

  include TenantScoped
  include SoftDeletable
  include Audited

  validates :variant_id, uniqueness: { scope: :marketplace_id, conditions: -> { kept } }
end
