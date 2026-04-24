class PageVersioningService
  MAX_VERSIONS = 6

  PAGE_SNAPSHOT_ATTRS = %w[id name title slug v2 template market_place_id].freeze
  COMPONENT_SNAPSHOT_ATTRS = %w[
    id components_id type_component items_type title row_index serialized_content
    items_ids parent_components_id search_id
  ].freeze

  def initialize(page)
    @page = page
  end

  def capture!(created_by: nil)
    PageVersion.create!(
      page: @page,
      version_number: next_version_number,
      snapshot: build_snapshot,
      created_by: created_by
    ).tap { cleanup! }
  end

  def restore!(version_number:)
    version = PageVersion.kept.find_by!(page: @page, version_number: version_number)

    ActiveRecord::Base.transaction do
      @page.landing_components.kept.discard_all
      id_map = {}

      version.components_data.each do |data|
        component = @page.landing_components.create!(
          data.slice(*COMPONENT_SNAPSHOT_ATTRS.excluding("id", "parent_components_id")).symbolize_keys
        )
        id_map[data["id"].to_s] = component.id

        if (option_data = data["market_place_option"]).present?
          component.create_market_place_option!(option_data.symbolize_keys)
        end

        Array(data["slides"]).each do |slide_data|
          component.slides.create!(slide_data.except("id").symbolize_keys)
        end
      end

      @page.landing_components.kept.find_each do |component|
        original = version.components_data.find { |item| item["components_id"] == component.components_id }
        next unless original && original["parent_components_id"].present?

        mapped_parent = id_map[original["parent_components_id"].to_s]
        component.update_column(:parent_components_id, mapped_parent) if mapped_parent.present?
      end
    end

    @page.clear_cache
    version
  end

  def versions
    PageVersion.where(page: @page).recent_first
  end

  private

  def build_snapshot
    {
      page: @page.attributes.slice(*PAGE_SNAPSHOT_ATTRS),
      components: @page.landing_components.kept.order(:row_index, :id).map do |component|
        component.attributes.slice(*COMPONENT_SNAPSHOT_ATTRS).merge(
          "market_place_option" => component.market_place_option&.attributes&.except("id", "created_at", "updated_at"),
          "slides" => component.slides.kept.map { |slide| slide.attributes.except("id", "created_at", "updated_at") }
        )
      end
    }
  end

  def next_version_number
    PageVersion.where(page: @page).maximum(:version_number).to_i + 1
  end

  def cleanup!
    keep_ids = PageVersion.where(page: @page).order(version_number: :desc).limit(MAX_VERSIONS).pluck(:id)
    PageVersion.where(page: @page).where.not(id: keep_ids).discard_all
  end
end
