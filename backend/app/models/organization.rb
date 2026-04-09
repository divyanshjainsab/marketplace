class Organization < ApplicationRecord
  include SoftDeletable
  include Audited

  has_many :organization_memberships, dependent: :destroy
  has_many :users, through: :organization_memberships
  has_many :marketplaces, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { conditions: -> { kept } }
end
