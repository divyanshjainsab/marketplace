class Category < ApplicationRecord
  include SoftDeletable
  include Audited

  belongs_to :parent, class_name: "Category", optional: true
  has_many :children, class_name: "Category", foreign_key: :parent_id, dependent: :restrict_with_exception

  has_many :products, dependent: :restrict_with_exception

  before_validation :assign_default_code

  validates :name, presence: true
  validates :code, presence: true, uniqueness: { conditions: -> { kept } }

  validate :parent_cannot_be_self
  validate :parent_cannot_create_cycle

  private

  def assign_default_code
    self.code = name.to_s.parameterize(separator: "_").presence if code.blank?
  end

  def parent_cannot_be_self
    return if parent_id.blank? && parent.blank?

    if parent_id.present? && id.present? && parent_id == id
      errors.add(:parent_id, "cannot reference itself")
      return
    end

    errors.add(:parent_id, "cannot reference itself") if parent.present? && parent.equal?(self)
  end

  def parent_cannot_create_cycle
    return if parent.blank?
    return if parent.equal?(self)
    return if id.present? && parent_id == id

    visited_ids = []
    current = parent

    while current.present?
      current_id = current.id

      if current.equal?(self) || (id.present? && current_id.present? && current_id == id)
        errors.add(:parent_id, "creates a cycle")
        break
      end

      if current_id.present?
        if visited_ids.include?(current_id)
          errors.add(:parent_id, "creates a cycle")
          break
        end
        visited_ids << current_id
      else
        break
      end

      current = current.parent
    end
  end
end
