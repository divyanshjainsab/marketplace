class User < ApplicationRecord
  include SoftDeletable
  include Audited

  has_many :organization_memberships, dependent: :destroy
  has_many :organizations, through: :organization_memberships

  validates :external_id, presence: true, uniqueness: { conditions: -> { kept } }
end
