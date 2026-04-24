class MarketPlaceOption < ApplicationRecord
  include Discard::Model

  self.discard_column = :deleted_at

  belongs_to :market_place, class_name: "Marketplace", foreign_key: :market_place_id, optional: true
  belongs_to :colorable, polymorphic: true, optional: true

  def colors
    grouped = {}
    values = attributes.slice(
      "primary_color_main",
      "primary_color_dark",
      "secondary_color_main",
      "secondary_color_dark",
      "background_color_main",
      "background_color_dark",
      "typography_color_main",
      "typography_color_dark",
      "dark_primary_color_main",
      "dark_primary_color_dark",
      "dark_secondary_color_main",
      "dark_secondary_color_dark",
      "dark_background_color_main",
      "dark_background_color_dark",
      "dark_typography_color_main",
      "dark_typography_color_dark"
    )

    values.each_with_index do |(key, value), index|
      next if value.blank?

      is_dark = key.start_with?("dark_")
      normalized_key = key.delete_prefix("dark_")
      name, variant = normalized_key.split("_color_")
      grouped[name] ||= { "name" => name, "variants" => { "light" => [], "dark" => [] } }
      grouped[name]["variants"][is_dark ? "dark" : "light"] << {
        "name" => variant,
        "id" => index,
        "color" => value
      }
    end

    grouped.values
  end
end
