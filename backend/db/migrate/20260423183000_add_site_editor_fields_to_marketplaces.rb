class AddSiteEditorFieldsToMarketplaces < ActiveRecord::Migration[7.1]
  def change
    change_table :marketplaces, bulk: true do |t|
      t.string :google_tracking_id
      t.string :pixel_tracking_id
      t.string :category_layout

      t.string :logo_url
      t.string :logo_public_id
      t.bigint :logo_version
      t.integer :logo_width
      t.integer :logo_height
    end

    add_index :marketplaces, :logo_public_id
  end
end

