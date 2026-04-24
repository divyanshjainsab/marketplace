class PageVersion < ApplicationRecord
  include Discard::Model

  self.discard_column = :deleted_at

  belongs_to :page

  validates :version_number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :snapshot, presence: true
  validates :version_number, uniqueness: { scope: :page_id }

  scope :recent_first, -> { kept.order(version_number: :desc) }

  def page_attributes
    snapshot["page"] || {}
  end

  def components_data
    snapshot["components"] || []
  end

  def summary
    {
      id: id,
      version_number: version_number,
      created_by: created_by,
      created_at: created_at,
      component_count: components_data.size
    }
  end
end
