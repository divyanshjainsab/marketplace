class Asset < ApplicationRecord
  include Discard::Model

  self.discard_column = :deleted_at

  belongs_to :market_place, class_name: "Marketplace", foreign_key: :market_place_id, optional: true
  belongs_to :recordable, polymorphic: true

  serialize :tags, coder: YAML, type: Array

  def recordable_type_label
    case recordable_type
    when "Page"
      "Page"
    when "LandingComponent"
      "#{recordable&.items_type}_#{recordable&.type_component}".to_s.humanize
    else
      recordable_type.to_s.humanize
    end
  end
end
