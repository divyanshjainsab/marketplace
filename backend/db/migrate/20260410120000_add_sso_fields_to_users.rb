class AddSsoFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :sso_user_id, :bigint
    add_column :users, :roles, :jsonb, null: false, default: []

    add_index :users, :sso_user_id
  end
end
