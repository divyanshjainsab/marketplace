class AddDevPortToMarketplaces < ActiveRecord::Migration[7.1]
  def change
    add_column :marketplaces, :dev_port, :integer

    add_index :marketplaces, :dev_port, unique: true, where: "dev_port IS NOT NULL AND discarded_at IS NULL"
  end
end

