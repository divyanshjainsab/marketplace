class User < ApplicationRecord
  include SoftDeletable
  include Audited

  has_many :organization_memberships, dependent: :destroy
  has_many :organizations, through: :organization_memberships
  has_many :marketplace_memberships, dependent: :destroy
  has_many :marketplaces, through: :marketplace_memberships

  validates :external_id, presence: true, uniqueness: { conditions: -> { kept } }

  def super_admin?
    Array(roles).include?("super_admin")
  end
end
