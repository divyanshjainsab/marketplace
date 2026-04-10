class AddProfileFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :phone_number, :string
    add_column :users, :avatar_url, :string

    add_index :users, :phone_number
  end
end

