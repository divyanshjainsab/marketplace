class Marketplace < ApplicationRecord
  belongs_to :organization

  include SoftDeletable
  include Audited

  has_many :listings, dependent: :destroy

  validates :name, presence: true
  validates :subdomain, presence: true, uniqueness: { conditions: -> { kept } }
  validates :custom_domain, uniqueness: { allow_nil: true, conditions: -> { kept } }
end
