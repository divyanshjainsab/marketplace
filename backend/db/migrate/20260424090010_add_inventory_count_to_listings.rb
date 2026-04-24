class AddInventoryCountToListings < ActiveRecord::Migration[7.1]
  def change
    add_column :listings, :inventory_count, :integer, null: false, default: 0
  end
end

