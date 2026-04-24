class AddAdminSettingsToOrganizations < ActiveRecord::Migration[7.1]
  def change
    add_column :organizations, :admin_settings, :jsonb, default: {}, null: false
    add_index :organizations, :admin_settings, using: :gin
  end
end
