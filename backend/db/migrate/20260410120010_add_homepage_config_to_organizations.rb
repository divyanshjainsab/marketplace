class AddHomepageConfigToOrganizations < ActiveRecord::Migration[7.1]
  def change
    add_column :organizations, :homepage_config, :jsonb, null: false, default: {}
    add_index :organizations, :homepage_config, using: :gin
  end
end
