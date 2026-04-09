class CreateMarketplaceMemberships < ActiveRecord::Migration[7.1]
  def change
    create_table :marketplace_memberships do |t|
      t.references :user, null: false, foreign_key: false
      t.references :marketplace, null: false, foreign_key: false
      t.string :role, null: false
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :marketplace_memberships, %i[user_id marketplace_id],
              unique: true,
              where: "discarded_at IS NULL",
              name: "index_mkt_memberships_on_user_and_marketplace_active"
    add_index :marketplace_memberships, :discarded_at
  end
end

