class Page < ApplicationRecord
  include Discard::Model

  self.discard_column = :deleted_at

  APP_SLUGS = %w[
    address cart checkout home product order-history profile saved-products search categories
  ].freeze

  belongs_to :market_place, class_name: "Marketplace", foreign_key: :market_place_id, optional: true

  has_many :landing_components, -> { kept.order(:row_index, :id) }, dependent: :destroy
  has_many :page_versions, -> { kept.order(version_number: :desc) }, dependent: :destroy
  has_many :assets, as: :recordable, dependent: :destroy

  validates :slug, uniqueness: { scope: [:market_place_id, :v2], conditions: -> { kept } }, allow_blank: -> { template? }

  before_validation :set_name, :set_title, :set_slug

  scope :v2_pages, -> { kept.where(v2: true) }
  scope :templates, -> { kept.where(template: true) }

  def clear_cache
    Rails.cache.delete_matched("site-editor:page:#{market_place_id}:#{slug}:*")
  end

  def home?
    slug == "home"
  end

  def custom
    APP_SLUGS.any? { |app_slug| slug.to_s.starts_with?(app_slug) } == false
  end

  private

  def set_name
    self.name ||= slug&.tr("_", " ")&.titleize
  end

  def set_title
    self.title ||= name
  end

  def set_slug
    self.slug ||= name&.parameterize
    self.slug = slug.to_s.gsub("/", "_").delete_prefix("_").delete_suffix("_")
  end
end
