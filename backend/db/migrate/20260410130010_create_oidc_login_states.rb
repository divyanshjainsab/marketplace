class CreateOidcLoginStates < ActiveRecord::Migration[7.1]
  def change
    create_table :oidc_login_states do |t|
      t.string :state, null: false
      t.string :client_id, null: false
      t.text :redirect_uri, null: false
      t.string :code_verifier, null: false
      t.string :nonce, null: false

      t.string :app, null: false
      t.string :return_to
      t.string :org_slug

      t.string :ip_address
      t.string :user_agent

      t.datetime :expires_at, null: false
      t.datetime :used_at

      t.timestamps
    end

    add_index :oidc_login_states, :state, unique: true
    add_index :oidc_login_states, :expires_at
    add_index :oidc_login_states, :used_at
  end
end

