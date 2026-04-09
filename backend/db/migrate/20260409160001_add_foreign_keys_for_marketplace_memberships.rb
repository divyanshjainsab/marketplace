class AddForeignKeysForMarketplaceMemberships < ActiveRecord::Migration[7.1]
  def change
    add_foreign_key :marketplace_memberships, :users
    add_foreign_key :marketplace_memberships, :marketplaces
  end
end

