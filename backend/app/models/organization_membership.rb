class OrganizationMembership < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  include SoftDeletable
  include Audited

  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :organization_id, conditions: -> { kept } }
end
