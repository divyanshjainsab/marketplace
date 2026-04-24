class Marketplace < ApplicationRecord
  belongs_to :organization

  include SoftDeletable
  include Audited

  has_many :listings, dependent: :destroy
  has_many :carts, dependent: :destroy
  has_many :marketplace_domains, dependent: :destroy
  has_many :marketplace_memberships, dependent: :destroy
  has_many :users, through: :marketplace_memberships

  # Core2 Site Editor compatibility (pages/components/themes live under market_place_id).
  has_many :pages, foreign_key: :market_place_id, inverse_of: :market_place
  has_one :market_place_option, foreign_key: :market_place_id, inverse_of: :market_place, dependent: :destroy
  has_many :assets, foreign_key: :market_place_id, inverse_of: :market_place
  has_many :searches, foreign_key: :market_place_id, inverse_of: :market_place

  validates :name, presence: true
  validates :custom_domain, presence: true, uniqueness: { conditions: -> { kept } }

  before_validation :normalize_custom_domain

  private

  def normalize_custom_domain
    self.custom_domain = custom_domain.to_s.strip.downcase.presence
  end
end
