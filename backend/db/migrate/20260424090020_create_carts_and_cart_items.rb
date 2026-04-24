class CreateCartsAndCartItems < ActiveRecord::Migration[7.1]
  def change
    create_table :carts do |t|
      t.references :marketplace, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.string :session_id, null: false
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :carts, %i[marketplace_id session_id],
              unique: true,
              where: "discarded_at IS NULL",
              name: "index_carts_on_marketplace_and_session_id_active"
    add_index :carts, %i[marketplace_id user_id],
              unique: true,
              where: "discarded_at IS NULL AND user_id IS NOT NULL",
              name: "index_carts_on_marketplace_and_user_id_active"
    add_index :carts, :discarded_at

    create_table :cart_items do |t|
      t.references :cart, null: false, foreign_key: true
      t.references :variant, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :cart_items, %i[cart_id variant_id],
              unique: true,
              where: "discarded_at IS NULL",
              name: "index_cart_items_on_cart_and_variant_active"
    add_index :cart_items, :discarded_at
  end
end

