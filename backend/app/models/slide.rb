class Slide < ApplicationRecord
  include Discard::Model

  self.discard_column = :deleted_at

  serialize :product_items_ids, coder: YAML, type: Array

  belongs_to :landing_component, optional: true
  belongs_to :categorizable, polymorphic: true, optional: true

  def category_component_id
    return nil if categorizable_type.blank? || categorizable_id.blank?

    "#{categorizable_type.underscore}_#{categorizable_id}"
  end
end
