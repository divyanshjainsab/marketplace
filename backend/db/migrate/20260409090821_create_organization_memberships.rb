class CreateOrganizationMemberships < ActiveRecord::Migration[7.1]
  def change
    create_table :organization_memberships do |t|
      t.references :user, null: false, foreign_key: false
      t.references :organization, null: false, foreign_key: false
      t.string :role, null: false
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :organization_memberships, %i[user_id organization_id],
              unique: true,
              where: "discarded_at IS NULL",
              name: "index_org_memberships_on_user_and_org_active"
    add_index :organization_memberships, :discarded_at
  end
end
