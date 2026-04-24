module SiteEditor
  class ComponentRenderer
    SEARCH_KEYS = %w[
      query category_id category_slug category_name product_type_id product_type_slug
      product_type_name product_id product_slug name price_from price_until with_listings
      in_stock sort_by sort_direction release_date_until release_date_from view_all_button
      category_ids product_type_ids descriptor_values descriptors page per_page
    ].freeze

    def initialize(component, marketplace: nil, template: false)
      @component = component
      @marketplace = marketplace || component.page&.market_place
      @template = template
      @search_params = (component.search&.search_params || {}).with_indifferent_access
    end

    def render
      base = {
        id: template ? nil : component.id,
        title: component.title,
        items_type: component.items_type,
        serialized_content: component.serialized_content || {},
        type_component: component.composite_type
      }
      base[:colors] = component.market_place_option.colors if component.market_place_option.present?

      case component.composite_type
      when "products_grid", "products_list", "products_carousel"
        base.merge(
          row_index: component.row_index,
          items_ids: Array(component.items_ids),
          items: render_products,
          has_filters_applied: Array(component.items_ids).empty?
        ).merge(search_payload)
      when "categories_product_types_grid", "categories_product_types_list", "categories_product_types_carousel"
        base.merge(
          row_index: component.row_index,
          items_ids: render_category_product_type_ids,
          entities: render_category_product_type_entities
        )
      when "categories_menutree"
        base.merge(
          row_index: component.row_index,
          items_ids: Array(component.items_ids),
          entities: render_menu_tree_entities
        )
      when "categories_jumbotron", "categories_banner", "categories_dummybanner"
        base.merge(
          row_index: component.row_index,
          slides: render_slides
        )
      when "grouped_items"
        base.merge(
          row_index: component.row_index,
          children: ordered_children(component).map { |child| self.class.new(child, marketplace: marketplace, template: template).render }
        )
      else
        base.merge(row_index: component.row_index)
      end
    end

    private

    attr_reader :component, :marketplace, :search_params, :template

    def search_payload
      payload = search_params.deep_dup
      payload[:view_all_button] = ActiveModel::Type::Boolean.new.cast(payload[:view_all_button])
      payload[:search_id] = component.search&.id
      payload
    end

    def render_products
      relation = Product.kept.includes(:category, :product_type, :variants)
      relation = relation.where(id: Array(component.items_ids).map(&:to_i)) if component.items_ids.present?
      relation = apply_product_filters(relation) if component.items_ids.blank? && search_params.present?
      relation = relation.order(:name)

      relation.limit(limit_count).map do |product|
        listing = listing_for(product)
        {
          id: product.id,
          database_id: product.id,
          listing_id: listing&.id,
          available: listing.present? ? 1 : 0,
          price_in_cents: listing&.price_cents,
          name: product.name,
          name_slug: product.name.to_s.parameterize,
          image: product.image_url,
          product_type_no_product_image_url: nil,
          category_name: product.category&.name,
          category_slug: product.category&.code || product.category&.name.to_s.parameterize,
          product_type_name: product.product_type&.name,
          product_type_slug: product.product_type&.code || product.product_type&.name.to_s.parameterize,
          market_price: nil,
          organization_price: nil,
          grouped_and_increased_organization_price: [],
          total_available_quantity: listing.present? ? 1 : 0
        }
      end
    end

    def apply_product_filters(relation)
      filtered = relation
      query = search_params["query"].presence || search_params[:query].presence
      filtered = filtered.suggest(query) if query.present?

      product_type_id = search_params["product_type_id"].presence || search_params[:product_type_id].presence
      filtered = filtered.where(product_type_id: product_type_id) if product_type_id.present?

      category_id = search_params["category_id"].presence || search_params[:category_id].presence
      filtered = filtered.where(category_id: category_id) if category_id.present?

      product_id = search_params["product_id"].presence || search_params[:product_id].presence
      filtered = filtered.where(id: product_id) if product_id.present?

      filtered
    end

    def listing_for(product)
      return nil if marketplace.blank?

      Listing.kept.find_by(marketplace_id: marketplace.id, product_id: product.id)
    end

    def limit_count
      Integer(search_params["per_page"].presence || search_params[:per_page].presence || 24, exception: false) || 24
    end

    def render_category_product_type_ids
      render_category_product_type_entities.map { |entity| "#{entity[:type]}_#{entity[:id]}" }
    end

    def render_category_product_type_entities
      Array(component.items_ids).filter_map do |raw_id|
        type, id = raw_id.to_s.split("_", 2)
        next if type.blank? || id.blank?

        case type
        when "category"
          category = Category.kept.find_by(id: id)
          next unless category

          {
            id: category.id,
            name: category.name,
            type: "category",
            name_slug: category.code.presence || category.name.to_s.parameterize,
            sub_title: nil,
            descendants: [],
            product_type_name_slug: nil,
            product_type_id: nil,
            image: nil
          }
        when "product", "producttype", "product_type"
          product_type = ProductType.kept.find_by(id: id)
          next unless product_type

          {
            id: product_type.id,
            name: product_type.name,
            type: "product_type",
            name_slug: product_type.code.presence || product_type.name.to_s.parameterize,
            sub_title: nil,
            descendants: [],
            product_type_name_slug: product_type.code.presence || product_type.name.to_s.parameterize,
            product_type_id: product_type.id,
            image: nil
          }
        end
      end
    end

    def render_menu_tree_entities
      Array(component.items_ids).filter_map do |raw_id|
        next unless raw_id.to_s.start_with?("category_")

        category = Category.kept.find_by(id: raw_id.to_s.delete_prefix("category_"))
        next unless category

        {
          id: category.id,
          name: category.name,
          name_slug: category.code.presence || category.name.to_s.parameterize,
          type: "category",
          product_type_id: nil,
          product_type_name_slug: nil,
          image: nil,
          descendants: []
        }
      end
    end

    def render_slides
      component.slides.map do |slide|
        {
          id: slide.id,
          title: slide.title,
          subtitle: slide.subtitle,
          button_label: slide.button_label,
          button_url: slide.button_url,
          image_url: slide.image_url,
          image_align: slide.image_align,
          mobile_image_url: slide.mobile_image_url,
          categorizable_id: slide.categorizable_id,
          categorizable_type: slide.categorizable_type,
          stored_file_uuid: slide.stored_file_uuid,
          items_ids: Array(slide.product_items_ids)
        }
      end
    end

    def ordered_children(parent)
      children = parent.child_components.to_a
      ids_order = Array(parent.serialized_content&.dig("children_component_ids") || parent.serialized_content&.dig(:children_component_ids))

      return children if ids_order.blank?

      indexed = children.index_by(&:components_id)
      ordered = ids_order.filter_map { |components_id| indexed[components_id] }
      remaining = children.reject { |child| ids_order.include?(child.components_id) }
      ordered + remaining
    end
  end
end
