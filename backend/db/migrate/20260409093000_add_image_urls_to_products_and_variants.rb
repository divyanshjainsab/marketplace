class AddImageUrlsToProductsAndVariants < ActiveRecord::Migration[7.1]
  def change
    add_column :products, :image_url, :text
    add_column :variants, :image_url, :text

    add_index :products, :image_url
    add_index :variants, :image_url
  end
end
