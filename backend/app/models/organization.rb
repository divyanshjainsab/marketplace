class Organization < ApplicationRecord
  include SoftDeletable
  include Audited

  has_many :organization_memberships, dependent: :destroy
  has_many :users, through: :organization_memberships
  has_many :marketplaces, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { conditions: -> { kept } }
  validates :subdomain, presence: true
  validates :subdomain, length: { maximum: 63 }, allow_nil: true
  validates :subdomain, format: { with: /\A[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\z/i }, allow_nil: true
  validates :subdomain, uniqueness: { conditions: -> { kept } }, allow_nil: true
  validates :dev_port, presence: true
  validates :dev_port, numericality: { only_integer: true, greater_than: 0, less_than: 65_536 }, allow_nil: true
  validates :dev_port, uniqueness: { conditions: -> { kept } }, allow_nil: true
end
