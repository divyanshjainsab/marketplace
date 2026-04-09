class AddForeignKeysForTenantModels < ActiveRecord::Migration[7.1]
  def change
    add_foreign_key :marketplaces, :organizations
    add_foreign_key :organization_memberships, :users
    add_foreign_key :organization_memberships, :organizations
  end
end
