class RemoveDevPortFromOrganizationsAndMarketplaces < ActiveRecord::Migration[7.1]
  def change
    if index_exists?(:marketplaces, :dev_port, name: "index_marketplaces_on_dev_port")
      remove_index :marketplaces, name: "index_marketplaces_on_dev_port"
    end
    remove_column :marketplaces, :dev_port, :integer if column_exists?(:marketplaces, :dev_port)

    if index_exists?(:organizations, :dev_port, name: "index_organizations_on_dev_port")
      remove_index :organizations, name: "index_organizations_on_dev_port"
    end
    remove_column :organizations, :dev_port, :integer if column_exists?(:organizations, :dev_port)
  end
end

