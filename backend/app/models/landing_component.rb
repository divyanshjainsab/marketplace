class LandingComponent < ApplicationRecord
  include Discard::Model

  self.discard_column = :deleted_at

  serialize :items_ids, coder: YAML, type: Array
  serialize :serialized_content, coder: YAML, type: Hash

  enum :type_component, {
    grid: 0,
    list: 1,
    carousel: 2,
    jumbotron: 3,
    banner: 4,
    card: 5,
    dummybanner: 6,
    video: 7,
    feed: 8,
    content: 9,
    items: 10,
    spacer: 11,
    button: 12,
    menutree: 13
  }, prefix: false

  enum :items_type, {
    products: 0,
    product_types: 1,
    categories: 2,
    listings: 3,
    categories_product_types: 4,
    text_content: 5,
    youtube: 6,
    rss: 7,
    static: 8,
    grouped: 9
  }, prefix: false

  belongs_to :search, optional: true
  belongs_to :page, optional: true
  belongs_to :parent_component, class_name: "LandingComponent", foreign_key: :parent_components_id, optional: true

  has_many :child_components,
           -> { kept.order(:row_index, :id) },
           class_name: "LandingComponent",
           foreign_key: :parent_components_id,
           dependent: :destroy
  has_many :slides, -> { kept.order(:id) }, dependent: :destroy
  has_one :market_place_option, as: :colorable, dependent: :destroy
  has_many :assets, as: :recordable, dependent: :destroy

  accepts_nested_attributes_for :slides, allow_destroy: true
  accepts_nested_attributes_for :market_place_option

  validates :row_index, presence: true

  scope :root_components, -> { kept.where(parent_components_id: nil) }

  before_validation :normalize_serialized_content_grid

  after_commit :clear_page_cache

  def composite_type
    "#{items_type}_#{type_component}"
  end

  private

  def clear_page_cache
    page&.clear_cache
  end

  # FormData payloads commonly store grid numbers as strings; coerce so the editor
  # and storefront renderer see integers and booleans consistently.
  def normalize_serialized_content_grid
    return if serialized_content.blank? || !serialized_content.is_a?(Hash)

    grid = serialized_content["grid"] || serialized_content[:grid]
    return unless grid.is_a?(Hash)

    grid.each_key do |breakpoint|
      cell = grid[breakpoint]
      grid[breakpoint] = normalize_grid_cell(cell) if cell.is_a?(Hash)
    end
  end

  def normalize_grid_cell(cell)
    normalized = cell.stringify_keys
    %w[x y w h minH maxH].each do |key|
      next unless normalized.key?(key)

      value = Integer(normalized[key], exception: false)
      normalized[key] = value if value
    end

    if normalized.key?("syncable")
      normalized["syncable"] = ActiveModel::Type::Boolean.new.cast(normalized["syncable"])
    end

    min_h = normalized["minH"]
    return normalized unless min_h.is_a?(Integer) && min_h.positive?

    h_val = normalized["h"]
    normalized["h"] = [h_val, min_h].max if h_val.is_a?(Integer) && h_val < min_h

    max_h = normalized["maxH"]
    if max_h.is_a?(Integer)
      normalized["maxH"] = [max_h, min_h + 1].max
    elsif normalized["h"].is_a?(Integer)
      normalized["maxH"] = [normalized["h"] + 1, min_h + 1].max
    end

    normalized
  end
end
