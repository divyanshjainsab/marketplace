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

ActiveRecord::Schema[7.1].define(version: 2026_04_20_120010) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_trgm"
  enable_extension "plpgsql"

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.citext "code", null: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_categories_on_code", unique: true, where: "(discarded_at IS NULL)"
    t.index ["discarded_at"], name: "index_categories_on_discarded_at"
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
    t.index ["discarded_at"], name: "index_listings_on_discarded_at"
    t.index ["marketplace_id", "variant_id"], name: "index_listings_on_marketplace_and_variant_active", unique: true, where: "(discarded_at IS NULL)"
    t.index ["marketplace_id"], name: "index_listings_on_marketplace_id"
    t.index ["product_id"], name: "index_listings_on_product_id"
    t.index ["variant_id"], name: "index_listings_on_variant_id"
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
    t.citext "subdomain", null: false
    t.citext "custom_domain"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["custom_domain"], name: "index_marketplaces_on_custom_domain", unique: true, where: "((custom_domain IS NOT NULL) AND (discarded_at IS NULL))"
    t.index ["discarded_at"], name: "index_marketplaces_on_discarded_at"
    t.index ["organization_id"], name: "index_marketplaces_on_organization_id"
    t.index ["subdomain"], name: "index_marketplaces_on_subdomain", unique: true, where: "(discarded_at IS NULL)"
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
    t.integer "dev_port"
    t.index ["dev_port"], name: "index_organizations_on_dev_port", unique: true
    t.index ["discarded_at"], name: "index_organizations_on_discarded_at"
    t.index ["homepage_config"], name: "index_organizations_on_homepage_config", using: :gin
    t.index ["host", "port"], name: "index_organizations_on_host_and_port_active", unique: true, where: "((discarded_at IS NULL) AND (host IS NOT NULL))"
    t.index ["host"], name: "index_organizations_on_host_active", where: "(discarded_at IS NULL)"
    t.index ["slug"], name: "index_organizations_on_slug", unique: true, where: "(discarded_at IS NULL)"
    t.index ["subdomain"], name: "index_organizations_on_subdomain", unique: true
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
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["discarded_at"], name: "index_products_on_discarded_at"
    t.index ["image_url"], name: "index_products_on_image_url"
    t.index ["metadata"], name: "index_products_on_metadata", using: :gin
    t.index ["name"], name: "index_products_on_name_trgm_active", opclass: :gin_trgm_ops, where: "(discarded_at IS NULL)", using: :gin
    t.index ["product_type_id"], name: "index_products_on_product_type_id"
    t.index ["search_document"], name: "index_products_on_search_document", using: :gin
    t.index ["sku"], name: "index_products_on_sku", unique: true, where: "(discarded_at IS NULL)"
    t.index ["sku"], name: "index_products_on_sku_trgm_active", opclass: :gin_trgm_ops, where: "(discarded_at IS NULL)", using: :gin
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
    t.index ["discarded_at"], name: "index_variants_on_discarded_at"
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

end
