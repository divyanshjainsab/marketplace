class AddCloudinaryImageMetadata < ActiveRecord::Migration[7.1]
  def change
    change_table :products, bulk: true do |t|
      t.string :image_public_id
      t.bigint :image_version
      t.integer :image_width
      t.integer :image_height
    end
    add_index :products, :image_public_id

    change_table :variants, bulk: true do |t|
      t.string :image_public_id
      t.bigint :image_version
      t.integer :image_width
      t.integer :image_height
    end
    add_index :variants, :image_public_id

    change_table :listings, bulk: true do |t|
      t.text :image_url
      t.string :image_public_id
      t.bigint :image_version
      t.integer :image_width
      t.integer :image_height
    end
    add_index :listings, :image_url
    add_index :listings, :image_public_id
  end
end
