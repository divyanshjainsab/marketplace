# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_04_24_120040) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_trgm"
  enable_extension "plpgsql"

  create_table "assets", force: :cascade do |t|
    t.string "name"
    t.text "tags"
    t.bigint "market_place_id"
    t.string "recordable_type", null: false
    t.bigint "recordable_id", null: false
    t.datetime "deleted_at"
    t.boolean "is_cc_template", default: false, null: false
    t.boolean "is_promo_template", default: false, null: false
    t.boolean "is_network", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_assets_on_deleted_at"
    t.index ["market_place_id"], name: "index_assets_on_market_place_id"
    t.index ["recordable_type", "recordable_id"], name: "index_assets_on_recordable"
  end

  create_table "cart_items", force: :cascade do |t|
    t.bigint "cart_id", null: false
    t.bigint "variant_id", null: false
    t.integer "quantity", null: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cart_id", "variant_id"], name: "index_cart_items_on_cart_and_variant_active", unique: true, where: "(discarded_at IS NULL)"
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["discarded_at"], name: "index_cart_items_on_discarded_at"
    t.index ["variant_id"], name: "index_cart_items_on_variant_id"
  end

  create_table "carts", force: :cascade do |t|
    t.bigint "marketplace_id", null: false
    t.bigint "user_id"
    t.string "session_id", null: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_carts_on_discarded_at"
    t.index ["marketplace_id", "session_id"], name: "index_carts_on_marketplace_and_session_id_active", unique: true, where: "(discarded_at IS NULL)"
    t.index ["marketplace_id", "user_id"], name: "index_carts_on_marketplace_and_user_id_active", unique: true, where: "((discarded_at IS NULL) AND (user_id IS NOT NULL))"
    t.index ["marketplace_id"], name: "index_carts_on_marketplace_id"
    t.index ["user_id"], name: "index_carts_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.citext "code", null: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "parent_id"
    t.index ["code"], name: "index_categories_on_code", unique: true, where: "(discarded_at IS NULL)"
    t.index ["discarded_at"], name: "index_categories_on_discarded_at"
    t.index ["parent_id"], name: "index_categories_on_parent_id"
    t.check_constraint "parent_id IS NULL OR parent_id <> id", name: "categories_parent_id_not_self"
  end

  create_table "landing_components", force: :cascade do |t|
    t.bigint "search_id"
    t.text "items_ids"
    t.integer "type_component"
    t.integer "items_type"
    t.string "title"
    t.integer "row_index", default: 0, null: false
    t.string "components_id"
    t.bigint "components_group_landing_id"
    t.text "serialized_content"
    t.datetime "deleted_at"
    t.bigint "page_id"
    t.bigint "parent_components_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["components_group_landing_id"], name: "index_landing_components_on_components_group_landing_id"
    t.index ["deleted_at"], name: "index_landing_components_on_deleted_at"
    t.index ["page_id"], name: "index_landing_components_on_page_id"
    t.index ["parent_components_id"], name: "index_landing_components_on_parent_components_id"
    t.index ["search_id"], name: "index_landing_components_on_search_id"
  end

  create_table "listings", force: :cascade do |t|
    t.bigint "marketplace_id", null: false
    t.bigint "product_id", null: false
    t.bigint "variant_id", null: false
    t.integer "price_cents"
    t.string "currency"
    t.string "status"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "image_url"
    t.string "image_public_id"
    t.bigint "image_version"
    t.integer "image_width"
    t.integer "image_height"
    t.integer "inventory_count", default: 0, null: false
    t.index ["discarded_at"], name: "index_listings_on_discarded_at"
    t.index ["image_public_id"], name: "index_listings_on_image_public_id"
    t.index ["image_url"], name: "index_listings_on_image_url"
    t.index ["marketplace_id", "variant_id"], name: "index_listings_on_marketplace_and_variant_active", unique: true, where: "(discarded_at IS NULL)"
    t.index ["marketplace_id"], name: "index_listings_on_marketplace_id"
    t.index ["product_id"], name: "index_listings_on_product_id"
    t.index ["variant_id"], name: "index_listings_on_variant_id"
  end

  create_table "market_place_options", force: :cascade do |t|
    t.string "primary_color_main"
    t.string "primary_color_dark"
    t.string "secondary_color_main"
    t.string "secondary_color_dark"
    t.string "background_color_main"
    t.string "background_color_dark"
    t.bigint "market_place_id"
    t.string "typography_color_main"
    t.string "typography_color_dark"
    t.integer "height"
    t.integer "width"
    t.string "dark_primary_color_main", default: "#1E8BB5"
    t.string "dark_primary_color_dark", default: "#16698A"
    t.string "dark_secondary_color_main", default: "#79A93C"
    t.string "dark_secondary_color_dark", default: "#4E6D29"
    t.string "dark_background_color_main", default: "#121212"
    t.string "dark_background_color_dark", default: "#1E1E1E"
    t.string "dark_typography_color_main", default: "#FFFFFF"
    t.string "dark_typography_color_dark", default: "#B3B3B3"
    t.string "colorable_type"
    t.bigint "colorable_id"
    t.string "header_background_color_main", default: "#2EBAE8"
    t.string "header_background_color_dark", default: "#2595ba"
    t.string "header_typography_color_main", default: "#0D0D0D"
    t.string "header_typography_color_dark", default: "#042636"
    t.string "dark_header_background_color_main", default: "#1E8BB5"
    t.string "dark_header_background_color_dark", default: "#16698A"
    t.string "dark_header_typography_color_main", default: "#FFFFFF"
    t.string "dark_header_typography_color_dark", default: "#B3B3B3"
    t.jsonb "header_content", default: {"blocks"=>[{"key"=>"siteeditor", "data"=>{"text-align"=>"center"}, "text"=>"Customize your header text", "type"=>"unstyled", "depth"=>0, "entityRanges"=>[], "inlineStyleRanges"=>[{"style"=>"color-rgb(255,255,255)", "length"=>26, "offset"=>0}]}], "entityMap"=>{}}
    t.datetime "deleted_at"
    t.boolean "use_infinite_scroll", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["colorable_type", "colorable_id"], name: "index_market_place_options_on_colorable"
    t.index ["deleted_at"], name: "index_market_place_options_on_deleted_at"
    t.index ["market_place_id"], name: "index_market_place_options_on_market_place_id"
  end

  create_table "marketplace_domains", force: :cascade do |t|
    t.bigint "marketplace_id", null: false
    t.citext "host", null: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_marketplace_domains_on_discarded_at"
    t.index ["host"], name: "index_marketplace_domains_on_host", unique: true, where: "(discarded_at IS NULL)"
    t.index ["marketplace_id"], name: "index_marketplace_domains_on_marketplace_id"
  end

  create_table "marketplace_memberships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "marketplace_id", null: false
    t.string "role", null: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_marketplace_memberships_on_discarded_at"
    t.index ["marketplace_id"], name: "index_marketplace_memberships_on_marketplace_id"
    t.index ["user_id", "marketplace_id"], name: "index_mkt_memberships_on_user_and_marketplace_active", unique: true, where: "(discarded_at IS NULL)"
    t.index ["user_id"], name: "index_marketplace_memberships_on_user_id"
  end

  create_table "marketplaces", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "name", null: false
    t.citext "custom_domain", null: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "google_tracking_id"
    t.string "pixel_tracking_id"
    t.string "category_layout"
    t.string "logo_url"
    t.string "logo_public_id"
    t.bigint "logo_version"
    t.integer "logo_width"
    t.integer "logo_height"
    t.index ["custom_domain"], name: "index_marketplaces_on_custom_domain", unique: true, where: "(discarded_at IS NULL)"
    t.index ["discarded_at"], name: "index_marketplaces_on_discarded_at"
    t.index ["logo_public_id"], name: "index_marketplaces_on_logo_public_id"
    t.index ["organization_id"], name: "index_marketplaces_on_organization_id"
  end

  create_table "organization_memberships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "organization_id", null: false
    t.string "role", null: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_organization_memberships_on_discarded_at"
    t.index ["organization_id"], name: "index_organization_memberships_on_organization_id"
    t.index ["user_id", "organization_id"], name: "index_org_memberships_on_user_and_org_active", unique: true, where: "(discarded_at IS NULL)"
    t.index ["user_id"], name: "index_organization_memberships_on_user_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.citext "slug", null: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "homepage_config", default: {}, null: false
    t.citext "host"
    t.integer "port"
    t.string "subdomain"
    t.jsonb "admin_settings", default: {}, null: false
    t.index ["admin_settings"], name: "index_organizations_on_admin_settings", using: :gin
    t.index ["discarded_at"], name: "index_organizations_on_discarded_at"
    t.index ["homepage_config"], name: "index_organizations_on_homepage_config", using: :gin
    t.index ["host", "port"], name: "index_organizations_on_host_and_port_active", unique: true, where: "((discarded_at IS NULL) AND (host IS NOT NULL))"
    t.index ["host"], name: "index_organizations_on_host_active", where: "(discarded_at IS NULL)"
    t.index ["slug"], name: "index_organizations_on_slug", unique: true, where: "(discarded_at IS NULL)"
    t.index ["subdomain"], name: "index_organizations_on_subdomain", unique: true
  end

  create_table "page_versions", force: :cascade do |t|
    t.bigint "page_id", null: false
    t.integer "version_number", null: false
    t.jsonb "snapshot", default: {}, null: false
    t.string "created_by"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_page_versions_on_deleted_at"
    t.index ["page_id", "version_number"], name: "index_page_versions_on_page_id_and_version_number", unique: true
    t.index ["page_id"], name: "index_page_versions_on_page_id"
  end

  create_table "pages", force: :cascade do |t|
    t.string "name"
    t.string "title"
    t.string "slug"
    t.bigint "market_place_id"
    t.boolean "template", default: false
    t.datetime "deleted_at"
    t.boolean "v2", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_pages_on_deleted_at"
    t.index ["market_place_id", "slug", "v2"], name: "index_pages_on_market_place_id_slug_v2", unique: true
    t.index ["market_place_id"], name: "index_pages_on_market_place_id"
  end

  create_table "product_types", force: :cascade do |t|
    t.string "name", null: false
    t.citext "code", null: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_product_types_on_code", unique: true, where: "(discarded_at IS NULL)"
    t.index ["discarded_at"], name: "index_product_types_on_discarded_at"
  end

  create_table "products", force: :cascade do |t|
    t.bigint "product_type_id", null: false
    t.bigint "category_id", null: false
    t.string "name", null: false
    t.citext "sku", null: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.virtual "search_document", type: :tsvector, as: "((setweight(to_tsvector('simple'::regconfig, (COALESCE(name, ''::character varying))::text), 'A'::\"char\") || setweight(to_tsvector('simple'::regconfig, (COALESCE(sku, ''::citext))::text), 'A'::\"char\")) || setweight(to_tsvector('simple'::regconfig, COALESCE((metadata)::text, ''::text)), 'B'::\"char\"))", stored: true
    t.text "image_url"
    t.string "image_public_id"
    t.bigint "image_version"
    t.integer "image_width"
    t.integer "image_height"
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["discarded_at"], name: "index_products_on_discarded_at"
    t.index ["image_public_id"], name: "index_products_on_image_public_id"
    t.index ["image_url"], name: "index_products_on_image_url"
    t.index ["metadata"], name: "index_products_on_metadata", using: :gin
    t.index ["name"], name: "index_products_on_name_trgm_active", opclass: :gin_trgm_ops, where: "(discarded_at IS NULL)", using: :gin
    t.index ["product_type_id"], name: "index_products_on_product_type_id"
    t.index ["search_document"], name: "index_products_on_search_document", using: :gin
    t.index ["sku"], name: "index_products_on_sku", unique: true, where: "(discarded_at IS NULL)"
    t.index ["sku"], name: "index_products_on_sku_trgm_active", opclass: :gin_trgm_ops, where: "(discarded_at IS NULL)", using: :gin
  end

  create_table "searches", force: :cascade do |t|
    t.text "search_params"
    t.string "type"
    t.bigint "market_place_id"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["market_place_id"], name: "index_searches_on_market_place_id"
    t.index ["type"], name: "index_searches_on_type"
  end

  create_table "slides", force: :cascade do |t|
    t.string "title"
    t.string "subtitle"
    t.bigint "jumbotron_id"
    t.string "button_label"
    t.string "button_url"
    t.bigint "landing_component_id"
    t.string "image_align"
    t.datetime "deleted_at"
    t.string "image_url", default: ""
    t.string "mobile_image_url", default: ""
    t.uuid "stored_file_uuid"
    t.string "categorizable_type"
    t.bigint "categorizable_id"
    t.text "product_items_ids"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["categorizable_type", "categorizable_id"], name: "index_slides_on_categorizable"
    t.index ["deleted_at"], name: "index_slides_on_deleted_at"
    t.index ["jumbotron_id"], name: "index_slides_on_jumbotron_id"
    t.index ["landing_component_id"], name: "index_slides_on_landing_component_id"
  end

  create_table "user_sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "refresh_token_digest", null: false
    t.bigint "org_id"
    t.jsonb "roles", default: [], null: false
    t.datetime "expires_at", null: false
    t.datetime "revoked_at"
    t.string "revoked_reason"
    t.datetime "last_used_at"
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_user_sessions_on_expires_at"
    t.index ["refresh_token_digest"], name: "index_user_sessions_on_refresh_token_digest", unique: true
    t.index ["revoked_at"], name: "index_user_sessions_on_revoked_at"
    t.index ["user_id"], name: "index_user_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.citext "external_id", null: false
    t.string "email"
    t.string "name"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "sso_user_id"
    t.jsonb "roles", default: [], null: false
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
    t.index ["external_id"], name: "index_users_on_external_id", unique: true, where: "(discarded_at IS NULL)"
    t.index ["sso_user_id"], name: "index_users_on_sso_user_id"
  end

  create_table "variants", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.string "name", null: false
    t.citext "sku", null: false
    t.jsonb "options", default: {}, null: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "image_url"
    t.string "image_public_id"
    t.bigint "image_version"
    t.integer "image_width"
    t.integer "image_height"
    t.index ["discarded_at"], name: "index_variants_on_discarded_at"
    t.index ["image_public_id"], name: "index_variants_on_image_public_id"
    t.index ["image_url"], name: "index_variants_on_image_url"
    t.index ["product_id"], name: "index_variants_on_product_id"
    t.index ["sku"], name: "index_variants_on_sku", unique: true, where: "(discarded_at IS NULL)"
  end

  create_table "versions", force: :cascade do |t|
    t.string "whodunnit"
    t.datetime "created_at"
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.string "event", null: false
    t.text "object"
    t.jsonb "object_changes"
    t.jsonb "controller_info"
  end

  add_foreign_key "assets", "marketplaces", column: "market_place_id"
  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "variants"
  add_foreign_key "carts", "marketplaces"
  add_foreign_key "carts", "users"
  add_foreign_key "categories", "categories", column: "parent_id"
  add_foreign_key "landing_components", "pages"
  add_foreign_key "page_versions", "pages"
  add_foreign_key "pages", "marketplaces", column: "market_place_id"
end
