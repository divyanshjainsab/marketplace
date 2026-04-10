class AddClaimsToRefreshTokens < ActiveRecord::Migration[7.1]
  def change
    add_column :refresh_tokens, :org_id, :bigint
    add_column :refresh_tokens, :roles, :jsonb, null: false, default: []

    add_index :refresh_tokens, :org_id
  end
end

