class CreateAttributesAndProductTypeAttributes < ActiveRecord::Migration[7.1]
  def change
    create_table :attributes do |t|
      t.string :name, null: false
      t.citext :code, null: false
      t.string :data_type, null: false
      t.text :description
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :attributes, :code, unique: true, where: "discarded_at IS NULL"
    add_index :attributes, :discarded_at

    create_table :product_type_attributes do |t|
      t.references :product_type, null: false, foreign_key: true
      t.references :attribute, null: false, foreign_key: { to_table: :attributes }
      t.boolean :required, null: false, default: false
      t.boolean :variant_level, null: false, default: false
      t.integer :position, null: false, default: 0
      t.jsonb :config, null: false, default: {}
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :product_type_attributes,
              %i[product_type_id attribute_id],
              unique: true,
              where: "discarded_at IS NULL",
              name: "index_product_type_attributes_on_type_and_attribute_active"
    add_index :product_type_attributes, :discarded_at
    add_index :product_type_attributes, :variant_level
  end
end

