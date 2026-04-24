module SiteEditor
  class ComponentUpsert
    SEARCH_ATTRIBUTE_KEYS = %w[
      query category_id category_slug category_name product_type_id product_type_slug
      product_type_name product_id product_slug name price_from price_until with_listings
      in_stock sort_by sort_direction release_date_until release_date_from view_all_button
      category_ids product_type_ids descriptor_values descriptors page per_page
    ].freeze

    def initialize(page:, component_params:, row_index:, parent_component: nil)
      @page = page
      @component_params = normalize(component_params)
      @row_index = row_index
      @parent_component = parent_component
    end

    def call
      children = Array(serialized_content.delete("children"))
      component = find_or_initialize_component
      component.assign_attributes(component_attributes)
      component.search = upsert_search(component.search)
      component.save!
      upsert_market_place_option(component)
      upsert_slides(component)
      kept_children_components_ids = upsert_children(component, children)
      persist_grouped_children_ids(component, kept_children_components_ids) if component.composite_type == "grouped_items"
      component
    end

    private

    attr_reader :page, :component_params, :row_index, :parent_component

    def normalize(value)
      case value
      when ActionController::Parameters
        normalize(value.to_unsafe_h)
      when Hash
        value.deep_stringify_keys.transform_values { |child| normalize(child) }
      when Array
        value.map { |child| normalize(child) }
      else
        value
      end
    end

    def find_or_initialize_component
      return page.landing_components.build if component_id.blank?

      page.landing_components.find_by(id: component_id) || page.landing_components.build
    end

    def component_id
      component_params["id"].presence
    end

    def component_attributes
      {
        title: component_params["title"],
        items_type: component_params["items_type"],
        type_component: component_params["type_component"],
        row_index: row_index,
        components_id: component_params["components_id"].presence || default_components_id,
        page: page,
        parent_components_id: parent_component&.id,
        items_ids: Array(component_params["items_ids"]).presence || [],
        serialized_content: serialized_content
      }.compact
    end

    def default_components_id
      "component-#{SecureRandom.uuid}"
    end

    def serialized_content
      @serialized_content ||= begin
        raw = component_params["serialized_content"]
        next_value = raw.is_a?(Hash) ? raw.deep_dup : {}
        next_value.delete("children")
        next_value
      end
    end

    def upsert_search(existing_search)
      payload = component_params.slice(*SEARCH_ATTRIBUTE_KEYS).compact_blank
      return nil if payload.empty? && existing_search.blank?

      search = existing_search || Search.new
      search.market_place_id = page.market_place_id
      search.search_params = payload
      search
    end

    def upsert_market_place_option(component)
      attrs = normalize(component_params["market_place_option_attributes"] || {})
      return if attrs.blank?

      option = component.market_place_option || component.build_market_place_option
      option.assign_attributes(attrs.except("id"))
      option.market_place_id ||= page.market_place_id
      option.save!
    end

    def upsert_slides(component)
      slides = Array(component_params["slides"])
      existing_ids = component.slides.pluck(:id)
      requested_ids = slides.map { |slide| slide["id"] }.compact.map(&:to_i)
      ids_to_remove = existing_ids - requested_ids
      component.slides.where(id: ids_to_remove).discard_all if ids_to_remove.any?

      slides.each do |slide_params|
        attrs = normalize(slide_params)
        slide = attrs["id"].present? ? component.slides.find_by(id: attrs["id"]) : nil
        slide ||= component.slides.build
        slide.assign_attributes(
          title: attrs["title"],
          subtitle: attrs["subtitle"],
          button_label: attrs["button_label"],
          button_url: attrs["button_url"],
          image_url: attrs["image_url"],
          image_align: attrs["image_align"],
          mobile_image_url: attrs["mobile_image_url"],
          stored_file_uuid: attrs["stored_file_uuid"] || attrs["new_stored_file_id"],
          categorizable_id: attrs["categorizable_id"],
          categorizable_type: attrs["categorizable_type"],
          product_items_ids: Array(attrs["items_ids"]).presence || []
        )
        slide.save!
      end
    end

    def upsert_children(component, children)
      kept_components_ids = []

      children.each_with_index do |child_params, index|
        child = self.class.new(
          page: page,
          component_params: child_params,
          row_index: index,
          parent_component: component
        ).call
        kept_components_ids << child.components_id
      end

      if kept_components_ids.any?
        component.child_components.where.not(components_id: kept_components_ids).discard_all
      else
        component.child_components.discard_all
      end

      kept_components_ids
    end

    def persist_grouped_children_ids(component, kept_components_ids)
      content = component.serialized_content.is_a?(Hash) ? component.serialized_content.deep_dup : {}
      content["children_component_ids"] = kept_components_ids
      component.update!(serialized_content: content)
    end
  end
end
