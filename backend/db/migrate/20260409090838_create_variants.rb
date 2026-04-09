class CreateVariants < ActiveRecord::Migration[7.1]
  def change
    create_table :variants do |t|
      t.references :product, null: false, foreign_key: true
      t.string :name, null: false
      t.citext :sku, null: false
      t.jsonb :options, null: false, default: {}
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :variants, :sku, unique: true, where: "discarded_at IS NULL"
    add_index :variants, :discarded_at
  end
end
