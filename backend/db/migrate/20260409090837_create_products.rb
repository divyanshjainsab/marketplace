class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products do |t|
      t.references :product_type, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.string :name, null: false
      t.citext :sku, null: false
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :products, :sku, unique: true, where: "discarded_at IS NULL"
    add_index :products, :discarded_at
  end
end
