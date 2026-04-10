class CreateUserSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :user_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :refresh_token_digest, null: false

      t.bigint :org_id
      t.jsonb :roles, null: false, default: []

      t.datetime :expires_at, null: false
      t.datetime :revoked_at
      t.string :revoked_reason
      t.datetime :last_used_at

      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end

    add_index :user_sessions, :refresh_token_digest, unique: true
    add_index :user_sessions, :expires_at
    add_index :user_sessions, :revoked_at
  end
end

