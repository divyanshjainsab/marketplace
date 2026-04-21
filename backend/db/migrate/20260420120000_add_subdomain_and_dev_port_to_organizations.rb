class AddSubdomainAndDevPortToOrganizations < ActiveRecord::Migration[7.1]
  def change
    add_column :organizations, :subdomain, :string
    add_column :organizations, :dev_port, :integer

    add_index :organizations, :subdomain, unique: true
    add_index :organizations, :dev_port, unique: true
  end
end

