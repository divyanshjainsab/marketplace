class CreateMarketplaces < ActiveRecord::Migration[7.1]
  def change
    create_table :marketplaces do |t|
      t.references :organization, null: false, foreign_key: false
      t.string :name, null: false
      t.citext :subdomain, null: false
      t.citext :custom_domain
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :marketplaces, :subdomain, unique: true, where: "discarded_at IS NULL"
    add_index :marketplaces, :custom_domain,
              unique: true,
              where: "custom_domain IS NOT NULL AND discarded_at IS NULL"
    add_index :marketplaces, :discarded_at
  end
end
