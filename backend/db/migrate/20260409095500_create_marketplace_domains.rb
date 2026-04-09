class CreateMarketplaceDomains < ActiveRecord::Migration[7.1]
  def change
    create_table :marketplace_domains do |t|
      t.references :marketplace, null: false, foreign_key: true
      t.citext :host, null: false
      t.datetime :discarded_at
      t.timestamps
    end

    add_index :marketplace_domains, :host, unique: true, where: "discarded_at IS NULL"
    add_index :marketplace_domains, :discarded_at
  end
end
