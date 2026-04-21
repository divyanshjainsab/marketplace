class AddSuperAdminToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :super_admin, :boolean, null: false, default: false
    add_index :users, :super_admin
  end
end

