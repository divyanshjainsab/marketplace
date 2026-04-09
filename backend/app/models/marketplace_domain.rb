class MarketplaceDomain < ApplicationRecord
  include SoftDeletable
  include Audited

  belongs_to :marketplace

  validates :host, presence: true, uniqueness: { conditions: -> { kept } }

  before_validation do
    self.host = host.to_s.downcase.presence
  end
end
