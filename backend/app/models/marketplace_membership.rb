class MarketplaceMembership < ApplicationRecord
  belongs_to :user
  belongs_to :marketplace

  include SoftDeletable
  include Audited

  validates :role, presence: true
  validates :role, inclusion: { in: ->(_) { Rbac::Registry.role_names } }
  validates :user_id, uniqueness: { scope: :marketplace_id, conditions: -> { kept } }
end
