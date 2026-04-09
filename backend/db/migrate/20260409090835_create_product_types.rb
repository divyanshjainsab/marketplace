class CreateProductTypes < ActiveRecord::Migration[7.1]
  def change
    create_table :product_types do |t|
      t.string :name, null: false
      t.citext :code, null: false
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :product_types, :code, unique: true, where: "discarded_at IS NULL"
    add_index :product_types, :discarded_at
  end
end
