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

ActiveRecord::Schema[7.1].define(version: 2026_04_10_170000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "email_otp_challenges", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "purpose", null: false
    t.string "code_digest", null: false
    t.datetime "expires_at", null: false
    t.datetime "consumed_at"
    t.integer "attempts", default: 0, null: false
    t.integer "sent_count", default: 1, null: false
    t.datetime "last_sent_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_email_otp_challenges_on_expires_at"
    t.index ["user_id", "purpose", "consumed_at"], name: "idx_email_otp_challenges_active_lookup"
    t.index ["user_id"], name: "index_email_otp_challenges_on_user_id"
  end

  create_table "jwt_denylists", force: :cascade do |t|
    t.string "jti", null: false
    t.datetime "exp", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exp"], name: "index_jwt_denylists_on_exp"
    t.index ["jti"], name: "index_jwt_denylists_on_jti", unique: true
  end

  create_table "refresh_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token_digest", null: false
    t.datetime "expires_at", null: false
    t.datetime "revoked_at"
    t.datetime "last_used_at"
    t.string "revoked_reason"
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "org_id"
    t.jsonb "roles", default: [], null: false
    t.index ["expires_at"], name: "index_refresh_tokens_on_expires_at"
    t.index ["org_id"], name: "index_refresh_tokens_on_org_id"
    t.index ["token_digest"], name: "index_refresh_tokens_on_token_digest", unique: true
    t.index ["user_id"], name: "index_refresh_tokens_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name"
    t.string "external_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_otp_secret"
    t.string "encrypted_otp_secret_iv"
    t.string "encrypted_otp_secret_salt"
    t.boolean "otp_required_for_login", default: false, null: false
    t.text "otp_backup_codes"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.boolean "email_verified", default: false, null: false
    t.integer "consumed_timestep", default: 0, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["email_verified"], name: "index_users_on_email_verified"
    t.index ["external_id"], name: "index_users_on_external_id", unique: true
    t.index ["otp_required_for_login"], name: "index_users_on_otp_required_for_login"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "email_otp_challenges", "users"
  add_foreign_key "refresh_tokens", "users"
end
