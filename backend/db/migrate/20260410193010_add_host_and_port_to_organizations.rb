class AddHostAndPortToOrganizations < ActiveRecord::Migration[7.1]
  def change
    add_column :organizations, :host, :citext
    add_column :organizations, :port, :integer

    add_index :organizations, :host, where: "discarded_at IS NULL", name: "index_organizations_on_host_active"
    add_index :organizations, [:host, :port],
              unique: true,
              where: "discarded_at IS NULL AND host IS NOT NULL",
              name: "index_organizations_on_host_and_port_active"
  end
end

