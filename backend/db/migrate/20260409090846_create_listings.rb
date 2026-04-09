class CreateListings < ActiveRecord::Migration[7.1]
  def change
    create_table :listings do |t|
      t.references :marketplace, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.references :variant, null: false, foreign_key: true
      t.integer :price_cents
      t.string :currency
      t.string :status
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :listings, %i[marketplace_id variant_id],
              unique: true,
              where: "discarded_at IS NULL",
              name: "index_listings_on_marketplace_and_variant_active"
    add_index :listings, :discarded_at
  end
end
