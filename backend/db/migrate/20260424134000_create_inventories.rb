class CreateInventories < ActiveRecord::Migration[7.1]
  def change
    create_table :inventories do |t|
      t.references :marketplace, null: false, foreign_key: true
      t.references :listing, null: false, foreign_key: true, index: false
      t.integer :quantity_on_hand, null: false, default: 0
      t.datetime :discarded_at

      t.timestamps
    end

    add_check_constraint :inventories, "quantity_on_hand >= 0", name: "inventories_quantity_on_hand_non_negative"
    add_index :inventories, :listing_id, unique: true
    add_index :inventories, :discarded_at

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          INSERT INTO inventories (marketplace_id, listing_id, quantity_on_hand, created_at, updated_at)
          SELECT listings.marketplace_id, listings.id, listings.inventory_count, NOW(), NOW()
          FROM listings
          WHERE listings.id IS NOT NULL
          ON CONFLICT (listing_id) DO NOTHING;
        SQL
      end
    end
  end
end
