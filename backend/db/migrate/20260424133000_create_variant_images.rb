class CreateVariantImages < ActiveRecord::Migration[7.1]
  def change
    create_table :variant_images do |t|
      t.references :variant, null: false, foreign_key: true
      t.integer :position, null: false, default: 0
      t.text :image_url
      t.string :image_public_id
      t.bigint :image_version
      t.integer :image_width
      t.integer :image_height
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :variant_images,
              %i[variant_id position],
              unique: true,
              where: "discarded_at IS NULL",
              name: "index_variant_images_on_variant_and_position_active"
    add_index :variant_images, :discarded_at
    add_index :variant_images, :image_public_id
  end
end

