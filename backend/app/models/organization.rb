class Organization < ApplicationRecord
  DEFAULT_ADMIN_SETTINGS = {
    "general" => {
      "store_name" => "",
      "branding" => "",
      "logo" => nil
    },
    "product_settings" => {
      "allow_product_sharing" => true,
      "isolation_mode" => false
    },
    "integrations" => {
      "google_analytics_id" => "",
      "meta_pixel_id" => "",
      "future_api_notes" => ""
    }
  }.freeze

  include SoftDeletable
  include Audited

  has_many :organization_memberships, dependent: :destroy
  has_many :users, through: :organization_memberships
  has_many :marketplaces, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { conditions: -> { kept } }
  validates :subdomain, presence: true
  validates :subdomain, length: { maximum: 63 }, allow_nil: true
  validates :subdomain, format: { with: /\A[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\z/i }, allow_nil: true
  validates :subdomain, uniqueness: { conditions: -> { kept } }, allow_nil: true

  def normalized_admin_settings
    normalize_admin_settings(admin_settings)
  end

  def product_sharing_scope
    product_settings = normalized_admin_settings.fetch("product_settings", {})
    sharing_enabled = ActiveModel::Type::Boolean.new.cast(product_settings["allow_product_sharing"])
    isolation_mode = ActiveModel::Type::Boolean.new.cast(product_settings["isolation_mode"])

    return :disabled unless sharing_enabled
    return :organization if isolation_mode

    :global
  end

  def settings_store_name
    normalized_admin_settings.dig("general", "store_name").presence || name
  end

  def update_admin_settings!(value)
    update!(admin_settings: normalize_admin_settings(value))
  end

  private

  def normalize_admin_settings(value)
    merged = DEFAULT_ADMIN_SETTINGS.deep_merge(normalize_settings_hash(value))
    merged["general"]["store_name"] = merged.dig("general", "store_name").to_s.strip
    merged["general"]["branding"] = merged.dig("general", "branding").to_s.strip
    merged["general"]["logo"] = normalize_logo_asset(merged.dig("general", "logo"))
    merged["product_settings"]["allow_product_sharing"] =
      ActiveModel::Type::Boolean.new.cast(merged.dig("product_settings", "allow_product_sharing"))
    merged["product_settings"]["isolation_mode"] =
      ActiveModel::Type::Boolean.new.cast(merged.dig("product_settings", "isolation_mode"))
    merged["integrations"]["google_analytics_id"] = merged.dig("integrations", "google_analytics_id").to_s.strip
    merged["integrations"]["meta_pixel_id"] = merged.dig("integrations", "meta_pixel_id").to_s.strip
    merged["integrations"]["future_api_notes"] = merged.dig("integrations", "future_api_notes").to_s.strip
    merged
  end

  def normalize_settings_hash(value)
    hash =
      if value.respond_to?(:to_h)
        value.to_h
      elsif value.is_a?(Hash)
        value
      else
        {}
      end

    hash.deep_stringify_keys
  end

  def normalize_logo_asset(value)
    return nil if value.blank?

    asset =
      if value.respond_to?(:to_h)
        value.to_h
      elsif value.is_a?(Hash)
        value
      else
        {}
      end

    normalized = asset.deep_stringify_keys.slice(
      "public_id",
      "optimized_url",
      "version",
      "width",
      "height",
      "urls"
    )

    return nil if normalized["public_id"].blank?

    normalized
  end
end
