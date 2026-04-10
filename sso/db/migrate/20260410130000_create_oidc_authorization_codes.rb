class CreateOidcAuthorizationCodes < ActiveRecord::Migration[7.1]
  def change
    create_table :oidc_authorization_codes do |t|
      t.string :code_digest, null: false
      t.string :client_id, null: false
      t.text :redirect_uri, null: false
      t.references :user, null: false, foreign_key: true

      t.string :scope, null: false, default: "openid profile"
      t.string :code_challenge, null: false
      t.string :code_challenge_method, null: false, default: "S256"
      t.string :nonce, null: false

      t.jsonb :claims, null: false, default: {}

      t.string :ip_address
      t.string :user_agent

      t.datetime :expires_at, null: false
      t.datetime :used_at

      t.timestamps
    end

    add_index :oidc_authorization_codes, :code_digest, unique: true
    add_index :oidc_authorization_codes, :expires_at
    add_index :oidc_authorization_codes, :used_at
  end
end

