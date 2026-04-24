class Search < ApplicationRecord
  include Discard::Model

  self.discard_column = :deleted_at

  belongs_to :market_place, class_name: "Marketplace", foreign_key: :market_place_id, optional: true

  serialize :search_params, coder: YAML, type: Hash
end
