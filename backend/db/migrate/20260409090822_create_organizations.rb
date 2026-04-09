class CreateOrganizations < ActiveRecord::Migration[7.1]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.citext :slug, null: false
      t.datetime :discarded_at

      t.timestamps
    end
    add_index :organizations, :slug, unique: true, where: "discarded_at IS NULL"
    add_index :organizations, :discarded_at
  end
end
