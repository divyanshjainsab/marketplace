module SiteEditor
  class HomepageConfigSanitizer
    SECTION_KEYS = %w[
      hero_banner
      featured_products
      featured_listings
      categories
      promotional_blocks
    ].freeze

    DEFAULT_LAYOUT_ORDER = SECTION_KEYS.freeze

    MAX_FEATURED = 12
    MAX_PROMO_BLOCKS = 6
    MAX_TEXT = 600
    MAX_URL = 4096

    def self.call(raw:, organization:)
      new(raw: raw, organization: organization).sanitize
    end

    def initialize(raw:, organization:)
      @raw = raw
      @organization = organization
    end

    def sanitize
      config = normalize_hash(raw)

      order = normalize_array(config["layout_order"]).map(&:to_s) & SECTION_KEYS
      order = DEFAULT_LAYOUT_ORDER if order.empty?

      {
        "layout_order" => order,
        "hero_banner" => sanitize_hero(config["hero_banner"]),
        "featured_products" => sanitize_id_list(config["featured_products"], key: "product_id"),
        "featured_listings" => sanitize_id_list(config["featured_listings"], key: "listing_id"),
        "categories" => sanitize_string_list(config["categories"], key: "code", max: MAX_FEATURED),
        "promotional_blocks" => sanitize_promo_blocks(config["promotional_blocks"])
      }
    end

    private

    attr_reader :raw

    def normalize_hash(value)
      return value.to_unsafe_h if value.respond_to?(:to_unsafe_h)
      return value if value.is_a?(Hash)

      {}
    end

    def normalize_array(value)
      return [] if value.nil?
      return value if value.is_a?(Array)

      [value]
    end

    def sanitize_hero(value)
      hero = normalize_hash(value)
      {
        "title" => sanitize_text(hero["title"], max: 120),
        "subtitle" => sanitize_text(hero["subtitle"], max: 220),
        "image" => sanitize_image(hero["image"]),
        "cta_text" => sanitize_text(hero["cta_text"], max: 40),
        "cta_href" => sanitize_href(hero["cta_href"])
      }.compact
    end

    def sanitize_id_list(value, key:)
      raw_items = normalize_array(value).take(MAX_FEATURED)
      ids = raw_items.map do |item|
        if item.is_a?(Hash) || item.respond_to?(:to_unsafe_h)
          hash = normalize_hash(item)
          hash[key].to_i
        else
          item.to_i
        end
      end
      ids.select { |id| id.positive? }.uniq.take(MAX_FEATURED)
    end

    def sanitize_string_list(value, key:, max:)
      raw_items = normalize_array(value).take(max)
      values = raw_items.map do |item|
        if item.is_a?(Hash) || item.respond_to?(:to_unsafe_h)
          hash = normalize_hash(item)
          hash[key].to_s
        else
          item.to_s
        end
      end

      values.map { |v| v.strip }.reject(&:blank?).uniq.take(max)
    end

    def sanitize_promo_blocks(value)
      blocks = normalize_array(value).take(MAX_PROMO_BLOCKS).map { |item| normalize_hash(item) }

      blocks.map do |block|
        {
          "title" => sanitize_text(block["title"], max: 80),
          "body" => sanitize_text(block["body"], max: MAX_TEXT),
          "image" => sanitize_image(block["image"]),
          "href" => sanitize_href(block["href"])
        }.compact
      end.reject { |block| block["title"].blank? }
    end

    def sanitize_text(value, max:)
      text = value.to_s.strip
      return nil if text.blank?

      text[0, max]
    end

    def sanitize_url(value)
      text = value.to_s.strip
      return nil if text.blank?
      return nil if text.length > MAX_URL
      return nil unless text.start_with?("https://")
      return nil unless Images::Delivery.cloudinary_url?(text)

      text
    end

    def sanitize_image(value)
      asset = Images::AssetPayload.normalize(payload: value, folder_prefix: site_editor_folder_prefix)
      return nil if asset.nil?

      Images::Delivery.asset(**asset)
    end

    def sanitize_href(value)
      text = value.to_s.strip
      return nil if text.blank?
      return nil if text.length > MAX_URL
      return text if text.start_with?("/")
      return text if text.start_with?("http://", "https://")

      nil
    end

    def site_editor_folder_prefix
      @site_editor_folder_prefix ||= Images::FolderPath.for(target: :site_editor, organization: @organization)
    end
  end
end
